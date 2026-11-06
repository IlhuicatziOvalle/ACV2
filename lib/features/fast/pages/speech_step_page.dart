import 'dart:async';
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

class SpeechStepPage extends ConsumerStatefulWidget {
  const SpeechStepPage({
    super.key,
    this.faceLevel,
    this.dropDetected = false,
  });

  final FaceLevel? faceLevel;
  final bool dropDetected;

  @override
  ConsumerState<SpeechStepPage> createState() => _SpeechStepPageState();
}

class _SpeechStepPageState extends ConsumerState<SpeechStepPage> {
  final FastService _fastService = FastService();
  int _remainingSeconds = FastConstants.speechSeconds;
  Timer? _timer;
  bool _isRecording = false;
  SpeechLevel? _result;
  String? _transcript;
  double? _similarity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(voicePromptsProvider)) return;
      TtsService.instance.speak(
        "Repite la siguiente frase de forma clara: '${FastConstants.targetPhrase}'. Tienes 10 segundos.",
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isLoading) return;

    setState(() {
      _isRecording = true;
      _remainingSeconds = FastConstants.speechSeconds;
      _result = null;
      _transcript = null;
      _similarity = null;
    });

    final recordingFuture = _fastService.runSpeech(
      FastConstants.targetPhrase,
      FastConstants.speechSeconds,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _isRecording = false;
          _isLoading = true; // Mostrar loading mientras termina de procesar
        }
      });
    });

    try {
      final analysis = await recordingFuture;

      if (mounted) {
        setState(() {
          _result = analysis.level;
          _transcript = analysis.transcript;
          _similarity = analysis.similarity;
          _isLoading = false;
          _isRecording = false;
          _timer?.cancel();
          _remainingSeconds = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = SpeechLevel.sin; // Fallback
          _transcript = "Error: $e";
          _similarity = 0.0;
          _isLoading = false;
          _isRecording = false;
          _timer?.cancel();
        });
      }
    }
  }

  /// Reinicia el estado y vuelve a lanzar el análisis desde cero.
  void _repeatTest() {
    _timer?.cancel();
    TtsService.instance.stop();
    setState(() {
      _result = null;
      _transcript = null;
      _similarity = null;
      _remainingSeconds = FastConstants.speechSeconds;
      _isRecording = false;
      _isLoading = false;
    });
    _startRecording();
  }

  void _proceedToDecision() {
    final faceLevel = widget.faceLevel ?? FaceLevel.sin;
    final dropDetected = widget.dropDetected;
    final speechLevel = _result ?? SpeechLevel.sin;

    context.push('/fast/decision', extra: {
      'speechLevel': speechLevel,
      'faceLevel': faceLevel,
      'dropDetected': dropDetected,
    });
  }

  RiskLevel? get _speechRiskLevel =>
      _result == null ? null : RiskStyles.fromSpeech(_result!);

  Widget _buildActionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isRecording) ...[
          const Icon(
            Icons.mic,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            '$_remainingSeconds s',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else if (_result != null && _speechRiskLevel != null) ...[
          Icon(
            Icons.check_circle,
            size: 56,
            color: RiskStyles.color(_speechRiskLevel!),
          ),
          const SizedBox(height: 12),
          Text(
            'Resultado: ${_result!.label} (${RiskStyles.badge(_speechRiskLevel!)})',
            style:
            RiskStyles.highlighted(level: _speechRiskLevel!, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          if ((_transcript?.isNotEmpty ?? false) || _similarity != null) ...[
            const SizedBox(height: 12),
            if (_transcript != null && _transcript!.isNotEmpty)
              Text(
                'Texto detectado: "$_transcript"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            if (_similarity != null)
              Text(
                'Similitud: ${(_similarity! * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
          const SizedBox(height: 16),
        ] else if (_isLoading) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          const Text(
            'Procesando audio...',
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

    if (_isRecording || _isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade600,
          padding: buttonPadding,
        ),
        child: Text(_isRecording ? 'Grabando...' : 'Procesando...'),
      );
    }

    if (_result == null) {
      return ElevatedButton(
        onPressed: _startRecording,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6CB9B7),
          foregroundColor: Colors.white,
          padding: buttonPadding,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic),
            SizedBox(width: 8),
            Text('Grabar'),
          ],
        ),
      );
    }

    // Cuando hay resultado se muestran dos botones
    final riskLevel = _speechRiskLevel!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _proceedToDecision,
          style: ElevatedButton.styleFrom(
            backgroundColor: RiskStyles.color(riskLevel),
            foregroundColor: Colors.white,
            padding: buttonPadding,
          ),
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _repeatTest,
          icon: const Icon(Icons.replay),
          label: const Text('Repetir'),
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            side: const BorderSide(color: Color(0xFF6CB9B7)),
            foregroundColor: const Color(0xFF6CB9B7),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('FAST - Habla'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Paso 3: Habla',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/fast_sintomas/speech_difficulty.png',
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const Text(
                'Frase a repetir:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Text(
                  FastConstants.targetPhrase,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
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