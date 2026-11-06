import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alerta_acv/core/constants/fast_constants.dart';
import 'package:alerta_acv/core/constants/risk_levels.dart';
import 'package:alerta_acv/core/theme/risk_styles.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/tts_service.dart';

class ArmsStepPage extends ConsumerStatefulWidget {
  const ArmsStepPage({super.key, this.faceLevel});

  final FaceLevel? faceLevel;

  @override
  ConsumerState<ArmsStepPage> createState() => _ArmsStepPageState();
}

class _ArmsStepPageState extends ConsumerState<ArmsStepPage> {
  final FastService _fastService = FastService();
  bool _isRunning = false;
  bool? _dropDetected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(voicePromptsProvider)) return;
      TtsService.instance.speak(
        "Levanta ambos brazos frente a ti a la altura de los hombros y mantenlos ahí por 10 segundos.",
      );
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isRunning = true;
      _isLoading = true;
    });

    // Llamar directamente al servicio nativo (abre la cámara)
    try {
      final dropDetected = await _fastService.runArms(FastConstants.armsSeconds);
      if (mounted) {
        setState(() {
          _dropDetected = dropDetected;
          _isLoading = false;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dropDetected = false; // Fallback en caso de error
          _isLoading = false;
          _isRunning = false;
        });
      }
    }
  }

  void _proceedToNext() {
    final faceLevel = widget.faceLevel ?? FaceLevel.sin;
    final dropDetected = _dropDetected ?? false;
    
    context.push('/fast/speech', extra: {
      'faceLevel': faceLevel,
      'dropDetected': dropDetected,
    });
  }

  RiskLevel? get _armRiskLevel =>
      _dropDetected == null ? null : RiskStyles.fromArms(_dropDetected!);

  Widget _buildActionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dropDetected != null && _armRiskLevel != null) ...[
          Icon(
            _dropDetected! ? Icons.warning_amber : Icons.check_circle,
            size: 56,
            color: RiskStyles.color(_armRiskLevel!),
          ),
          const SizedBox(height: 12),
          Text(
            _dropDetected!
                ? 'Resultado: Caída detectada (${RiskStyles.badge(_armRiskLevel!)})'
                : 'Resultado: Sin caída detectada (${RiskStyles.badge(_armRiskLevel!)})',
            style: RiskStyles.highlighted(level: _armRiskLevel!, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else if (_isLoading || _isRunning) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          const Text(
            'Analizando brazos...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        _buildPrimaryButton(),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    const buttonPadding = EdgeInsets.symmetric(vertical: 14);

    if (_isLoading || _isRunning) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade600,
          padding: buttonPadding,
        ),
        child: const Text('Analizando...'),
      );
    }

    if (_dropDetected == null) {
      return ElevatedButton(
        onPressed: _startTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6CB9B7),
          foregroundColor: Colors.white,
          padding: buttonPadding,
        ),
        child: const Text('Iniciar'),
      );
    }

    final riskLevel = _armRiskLevel!;
    return ElevatedButton(
      onPressed: _proceedToNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: RiskStyles.color(riskLevel),
        foregroundColor: Colors.white,
        padding: buttonPadding,
      ),
      child: const Text('Continuar'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('FAST - Brazos'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Paso 2: Brazos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/fast_sintomas/arm_weakness.png',
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const Text(
                'Instrucciones:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pídele que levante ambos brazos al frente y los mantenga arriba mientras contamos 10 segundos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildActionPanel(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
