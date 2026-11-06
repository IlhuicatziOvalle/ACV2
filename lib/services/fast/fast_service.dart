import 'package:alerta_acv/core/constants/risk_levels.dart';
import 'package:alerta_acv/services/fast_api.g.dart';

/// Servicio que wrappea las APIs nativas de Pigeon
/// Convierte los resultados de Pigeon a los enums usados por la UI
class SpeechAnalysis {
  SpeechAnalysis({
    required this.level,
    required this.transcript,
    required this.similarity,
  });

  final SpeechLevel level;
  final String transcript;
  final double similarity;
}

class FastService {
  FastService._internal({
    FastNativeApi? fastNativeApi,
    DeviceApi? deviceApi,
  })  : _fastNativeApi = fastNativeApi ?? FastNativeApi(),
        _deviceApi = deviceApi ?? DeviceApi();

  static final FastService _instance = FastService._internal();
  factory FastService() => _instance;

  final FastNativeApi _fastNativeApi;
  final DeviceApi _deviceApi;

  Future<void>? _initFuture;

  /// Inicializa los recursos nativos
  Future<void> init() {
    _initFuture ??= _fastNativeApi.initialize();
    return _initFuture!;
  }

  /// Ejecuta la prueba de habla y devuelve datos del análisis
  Future<SpeechAnalysis> runSpeech(String targetPhrase, int maxSeconds) async {
    final result = await _fastNativeApi.runSpeech(targetPhrase, maxSeconds);
    
    // Convertir el nivel de string a enum
    final level = switch (result.level) {
      'Sin' => SpeechLevel.sin,
      'Leve' => SpeechLevel.leve,
      'Fuerte' => SpeechLevel.fuerte,
      _ => SpeechLevel.sin,
    };

    return SpeechAnalysis(
      level: level,
      transcript: result.transcript,
      similarity: result.similarity,
    );
  }

  /// Ejecuta la prueba de cara y devuelve el nivel de asimetría
  Future<FaceLevel> runFace(int maxMillis) async {
    final result = await _fastNativeApi.runFace(maxMillis);
    
    // Convertir el nivel de string a enum
    switch (result.level) {
      case 'Sin':
        return FaceLevel.sin;
      case 'Leve':
        return FaceLevel.leve;
      case 'Fuerte':
        return FaceLevel.fuerte;
      default:
        return FaceLevel.sin;
    }
  }

  /// Ejecuta la prueba de brazos y devuelve si se detectó caída
  Future<bool> runArms(int seconds) async {
    final result = await _fastNativeApi.runArms(seconds);
    return result.dropDetected;
  }

  /// Realiza una llamada al 911
  Future<bool> placeCall911() async {
    return await _deviceApi.placeCall911();
  }

  /// Envía un SMS de emergencia
  Future<bool> sendEmergencySms(String message, bool includeLocation) async {
    return await _deviceApi.sendEmergencySms(message, includeLocation);
  }

  /// Libera los recursos nativos
  Future<void> dispose() async {
    await _fastNativeApi.dispose();
    _initFuture = null;
  }
}

