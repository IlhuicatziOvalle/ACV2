/// Niveles de riesgo para la evaluación FAST
enum RiskLevel {
  bajo,
  medio,
  alto,
}

/// Niveles de dificultad para Speech
enum SpeechLevel {
  sin,
  leve,
  fuerte,
}

/// Niveles de asimetría para Face
enum FaceLevel {
  sin,
  leve,
  fuerte,
}

/// Extensión para obtener el texto en español
extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.bajo:
        return 'Bajo';
      case RiskLevel.medio:
        return 'Medio';
      case RiskLevel.alto:
        return 'Alto';
    }
  }
}

extension SpeechLevelExtension on SpeechLevel {
  String get label {
    switch (this) {
      case SpeechLevel.sin:
        return 'Sin dificultad';
      case SpeechLevel.leve:
        return 'Leve';
      case SpeechLevel.fuerte:
        return 'Fuerte';
    }
  }
}

extension FaceLevelExtension on FaceLevel {
  String get label {
    switch (this) {
      case FaceLevel.sin:
        return 'Sin asimetría';
      case FaceLevel.leve:
        return 'Leve';
      case FaceLevel.fuerte:
        return 'Fuerte';
    }
  }
}

/// Función para combinar resultados FAST y determinar el riesgo global
RiskLevel combineFastResults({
  required SpeechLevel speechLevel,
  required FaceLevel faceLevel,
  required bool dropDetected,
}) {
  // ALTO si:
  // - habla fuerte, o
  // - cara fuerte, o
  // - caída detectada, o
  // - >= 2 leves
  int mildCount = 0;
  if (speechLevel == SpeechLevel.leve) mildCount++;
  if (faceLevel == FaceLevel.leve) mildCount++;

  if (speechLevel == SpeechLevel.fuerte ||
      faceLevel == FaceLevel.fuerte ||
      dropDetected ||
      mildCount >= 2) {
    return RiskLevel.alto;
  }

  // MEDIO si exactamente 1 leve
  if (mildCount == 1) {
    return RiskLevel.medio;
  }

  // BAJO si 0 leves/fuertes
  return RiskLevel.bajo;
}

