import 'package:pigeon/pigeon.dart';

/// Resultado de la prueba de habla
class SpeechResult {
  SpeechResult({
    required this.transcript,
    required this.similarity,
    required this.level,
  });

  final String transcript;
  final double similarity;
  final String level; // "Sin", "Leve", "Fuerte"
}

/// Resultado de la prueba de cara
class FaceResult {
  FaceResult({
    required this.asymmetry,
    required this.level,
    required this.faceFound,
    required this.lowLight,
  });

  final double asymmetry;
  final String level; // "Sin", "Leve", "Fuerte"
  final bool faceFound;
  final bool lowLight;
}

/// Resultado de la prueba de brazos
class ArmsResult {
  ArmsResult({
    required this.deltaY,
    required this.dropDetected,
  });

  final double deltaY;
  final bool dropDetected;
}

/// API nativa para pruebas FAST
@HostApi()
abstract class FastNativeApi {
  /// Inicializa los recursos nativos necesarios
  void initialize();

  /// Ejecuta la prueba de habla
  /// [targetPhrase] es la frase objetivo a comparar
  /// [maxSeconds] es el tiempo máximo de grabación
  @async
  SpeechResult runSpeech(String targetPhrase, int maxSeconds);

  /// Ejecuta la prueba de cara
  /// [maxMillis] es el tiempo máximo en milisegundos
  @async
  FaceResult runFace(int maxMillis);

  /// Ejecuta la prueba de brazos
  /// [seconds] es la duración de la prueba
  @async
  ArmsResult runArms(int seconds);

  /// Libera los recursos nativos
  void dispose();
}

/// API nativa para funciones del dispositivo
@HostApi()
abstract class DeviceApi {
  /// Realiza una llamada al 911
  bool placeCall911();

  /// Envía un SMS de emergencia
  /// [message] es el mensaje a enviar
  /// [includeLocation] indica si se debe incluir la ubicación
  bool sendEmergencySms(String message, bool includeLocation);
}

