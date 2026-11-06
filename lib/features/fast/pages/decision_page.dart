import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alerta_acv/core/constants/fast_constants.dart';
import 'package:alerta_acv/core/constants/risk_levels.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/core/theme/risk_styles.dart';
import 'package:alerta_acv/models/test_result.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/phone_utils.dart';
import 'package:alerta_acv/services/sms_service.dart';
import 'package:alerta_acv/widgets/countdown_dialog.dart';

class DecisionPage extends StatefulWidget {
  const DecisionPage({
    super.key,
    required this.speechLevel,
    required this.faceLevel,
    required this.dropDetected,
  });

  final SpeechLevel? speechLevel;
  final FaceLevel? faceLevel;
  final bool dropDetected;

  @override
  State<DecisionPage> createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage> {
  late RiskLevel _riskLevel;
  int _countdown = FastConstants.emergencyCountdownSeconds;
  Timer? _countdownTimer;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    final speechLevel = widget.speechLevel ?? SpeechLevel.sin;
    final faceLevel = widget.faceLevel ?? FaceLevel.sin;
    final dropDetected = widget.dropDetected;

    _riskLevel = combineFastResults(
      speechLevel: speechLevel,
      faceLevel: faceLevel,
      dropDetected: dropDetected,
    );

    if (_riskLevel == RiskLevel.alto) {
      _startCountdown();
    }
    
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      final result = TestResult(
        date: DateTime.now(),
        speechLevel: widget.speechLevel?.label ?? 'N/A',
        faceLevel: widget.faceLevel?.label ?? 'N/A',
        armDrop: widget.dropDetected,
        riskLevel: _riskLevel.label,
      );
      await DatabaseService.instance.saveTestResult(result);
    } catch (e) {
      debugPrint('Error saving result: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdown = FastConstants.emergencyCountdownSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _executeEmergencyProtocol();
        }
      });
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _showCountdown = false;
    });
  }

  Future<void> _call911WithCountdown() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownDialog(
        seconds: 10,
        onComplete: _executeEmergencyProtocol,
      ),
    );
  }

  Future<void> _executeEmergencyProtocol() async {
    // 1. Llamar al 911 usando la integración nativa (Android/iOS)
    try {
      final fastService = FastService();
      final success = await fastService.placeCall911();

      // Fallback: si por alguna razón la llamada nativa falla, abrir marcador
      if (!success && mounted) {
        await PhoneUtils.launchDialer(context, '911');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al llamar al 911: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // 2. Enviar SMS a contactos de emergencia solo si el toggle está activado
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final autoSms = ref.watch(autoSmsProvider);
          if (autoSms) {
            () async {
              try {
                final contacts = await DatabaseService.instance.getAllContacts();
                if (contacts.isNotEmpty) {
                  final phoneNumbers = contacts.map((c) => c.phoneNumber).toList();
                  final errors = await SmsService.sendEmergencySmsToMultiple(phoneNumbers);
                  if (mounted && errors.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SMS de emergencia enviado a tus contactos'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error enviando SMS: $e');
              }
            }();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _alertContacts() async {
    try {
      final contacts = await DatabaseService.instance.getAllContacts();
      
      if (contacts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay contactos de emergencia configurados'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final phoneNumbers = contacts.map((c) => c.phoneNumber).toList();
      final errors = await SmsService.sendEmergencySmsToMultiple(phoneNumbers);
      
      if (!mounted) return;
      
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS enviado a ${phoneNumbers.length} contacto(s)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Algunos SMS fallaron: ${errors.length} error(es)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar SMS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  RiskLevel get _speechDetailRisk =>
      RiskStyles.fromSpeech(widget.speechLevel ?? SpeechLevel.sin);

  RiskLevel get _faceDetailRisk =>
      RiskStyles.fromFace(widget.faceLevel ?? FaceLevel.sin);

  RiskLevel get _armDetailRisk =>
      RiskStyles.fromArms(widget.dropDetected);

  @override
  Widget build(BuildContext context) {
    final overallColor = RiskStyles.color(_riskLevel);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Resultado FAST'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 8),
              const Text(
                'Resultado de la prueba FAST',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Nivel de riesgo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: overallColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: overallColor,
                    width: 3,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Riesgo: ${_riskLevel.label}',
                      style: RiskStyles.highlighted(level: _riskLevel, fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Detalles
              const Text(
                'Detalles:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Habla',
                widget.speechLevel?.label ?? 'Sin dificultad',
                _speechDetailRisk,
              ),
              _buildDetailRow(
                'Cara',
                widget.faceLevel?.label ?? 'Sin asimetría',
                _faceDetailRisk,
              ),
              _buildDetailRow(
                'Brazos',
                widget.dropDetected ? 'Caída detectada' : 'Sin caída',
                _armDetailRisk,
              ),
              const SizedBox(height: 32),
              // Countdown para riesgo alto
              if (_showCountdown && _riskLevel == RiskLevel.alto) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Llamando al 911 en:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _cancelCountdown,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Botones de acción
              if (_riskLevel == RiskLevel.alto && !_showCountdown) ...[
                ElevatedButton(
                  onPressed: _call911WithCountdown,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency),
                      SizedBox(width: 8),
                      Text(
                        'Llamar al 911',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Botón para alertar contactos
              ElevatedButton(
                onPressed: _alertContacts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message),
                    SizedBox(width: 8),
                    Text(
                      'Alertar a contactos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Botón para volver al inicio
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al inicio'),
              ),
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDetailRow(String label, String value, RiskLevel riskLevel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '$value · ${RiskStyles.badge(riskLevel)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: RiskStyles.highlighted(level: riskLevel, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

