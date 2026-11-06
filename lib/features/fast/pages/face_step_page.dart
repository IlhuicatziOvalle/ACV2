import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:alerta_acv/core/constants/fast_constants.dart';
import 'package:alerta_acv/core/constants/risk_levels.dart';
import 'package:alerta_acv/core/theme/risk_styles.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/tts_service.dart';

class FaceStepPage extends ConsumerStatefulWidget {
  const FaceStepPage({super.key});

  @override
  ConsumerState<FaceStepPage> createState() => _FaceStepPageState();
}

class _FaceStepPageState extends ConsumerState<FaceStepPage> {
  final FastService _fastService = FastService();
  int _remainingSeconds = FastConstants.faceSeconds;
  Timer? _timer;
  bool _isRunning = false;
  FaceLevel? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(voicePromptsProvider)) return;
      TtsService.instance.speak(
        "Por favor, sonríe mostrando los dientes para analizar la simetría de tu rostro. Mantén el teléfono frente a ti.",
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _startTimer() async {
    setState(() {
      _isRunning = true;
      _remainingSeconds = FastConstants.faceSeconds;
      _isLoading = false;
    });

    final maxMillis = FastConstants.faceSeconds * 1000;
    final faceFuture = _fastService.runFace(maxMillis);
    
    final completer = Completer<void>();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
    });

    try {
      // Esperamos a que termine el análisis nativo
      final result = await faceFuture;
      
      // Aseguramos que el timer visual también haya terminado
      await completer.future;
      
      if (mounted) {
        setState(() {
          _result = result;
          _isRunning = false;
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      _timer?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }

      final message = e.code == 'PERMISSION_DENIED'
          ? 'Se requiere permiso de cámara para esta prueba'
          : 'Error en análisis: ${e.message ?? e.code}';

      if (mounted) {
        setState(() {
          _result = null;
          _isRunning = false;
          _isLoading = false;
          _remainingSeconds = FastConstants.faceSeconds;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      _timer?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }

      if (mounted) {
        setState(() {
          _result = FaceLevel.sin; // Fallback
          _isRunning = false;
          _isLoading = false;
          _remainingSeconds = FastConstants.faceSeconds;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en análisis: $e')),
        );
      }
    }
  }

  void _proceedToNext() {
    final faceLevel = _result ?? FaceLevel.sin;
    
    context.push('/fast/arms', extra: {
      'faceLevel': faceLevel,
    });
  }

  RiskLevel? get _faceRiskLevel =>
      _result == null ? null : RiskStyles.fromFace(_result!);

  Widget _buildActionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isRunning) ...[
          Text(
            '$_remainingSeconds s',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        if (_result != null && _faceRiskLevel != null) ...[
          Text(
            'Resultado: ${_result!.label} (${RiskStyles.badge(_faceRiskLevel!)})',
            style: RiskStyles.highlighted(level: _faceRiskLevel!, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        _buildPrimaryButton(),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    const buttonPadding = EdgeInsets.symmetric(vertical: 14);

    if (_isRunning) {
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

/////////-----------------BOTON INICIAR PRUEBA--------------------/////////////
    if (_result == null) {
      return ElevatedButton(
        onPressed: _startTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 25, 118, 210),
          foregroundColor: Colors.white,
          padding: buttonPadding,
        ),
        child: const Text('Iniciar',
        style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ))
      );
    }
    

    final riskLevel = _faceRiskLevel!;
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

////////////////////////////////////////////////////////////////////////////
/////////-----------------PESTAÑA PRUEBA 1--------------------/////////////
//////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 247, 250), //color de fondo de la pestaña
      appBar: AppBar( //barra de arriba
        backgroundColor: const Color.fromARGB(255, 243, 247, 250),//color de fondo de la barra
        // Reemplazamos la flecha automática por una personalizada
        leading: Center(
          child: Container(
          // Ajustamos el tamaño del círculo blanco
            width: 80,
            height: 80,
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco para que resalte
                shape: BoxShape.circle, // Forma circular
              ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 40),
              onPressed: () {
                Navigator.pop(context); // Acción para volver a la pantalla anterior
              },
            ),
          ),
        ),
        title: const Text('Paso 1: Cara',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ), //titulo de arriba de la pantalla
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             const SizedBox(height: 15),
              Image.asset(
                'assets/images/fast_sintomas/face_droping.png', //la imagen en cuestion del ejemplo
                height: 360,
               
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 15),
              // Mostrar instrucciones solamente antes de obtener el resultado
              if (_result == null) //con esto se evita que aparezcan las instrucciones cambiando el estado
              const Text(
                'Instrucciones:', //Titulo para las instrucciones
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Mostrar instrucciones solamente antes de obtener el resultado
              if (_result == null) //con esto se evita que aparezcan las instrucciones cambiando el estado
              const Text(
                'Coloca a la persona en cuadro y pídele que sonría mostrando los dientes por 5 segundos', //Las instrucciones en si
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              _buildActionPanel(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, //boton de iniciar?
    );
  }
////////////////////////////////////////////////////////////////////////////
/////////-----------------PESTAÑA PRUEBA 1--------------------/////////////
//////////////////////////////////////////////////////////////////////////
}
