/// Constantes para la evaluación FAST (Face, Arms, Speech, Time)
class FastConstants {
  // Duraciones en segundos
  static const int faceSeconds = 5;
  static const int armsSeconds = 10;
  static const int speechSeconds = 4;

  // Umbrales de habla (similaridad 0-1)
  static const double speechNoDifficulty = 0.80;
  static const double speechMildThreshold = 0.60;

  // Umbrales de cara (asimetría 0-1)
  static const double faceNoAsymmetry = 0.08;
  static const double faceMildThreshold = 0.14;

  // Umbrales de brazos
  static const double armsDropThreshold = 0.20; // delta(t) >= 0.20
  static const int armsDropDurationSeconds = 2; // durante >= 2s

  // Frase objetivo para Speech
  static const String targetPhrase = 'Hoy es un buen día para ayudar.';

  // Tiempo de cuenta regresiva antes de llamar al 911 (segundos)
  static const int emergencyCountdownSeconds = 10;
}

