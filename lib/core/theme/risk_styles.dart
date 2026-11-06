import 'package:flutter/material.dart';
import 'package:alerta_acv/core/constants/risk_levels.dart';

class RiskStyles {
  static const Map<RiskLevel, Color> _colorMap = {
    RiskLevel.bajo: Color(0xFF2E7D32),
    RiskLevel.medio: Color(0xFFF9A825),
    RiskLevel.alto: Color(0xFFC62828),
  };

  static Color color(RiskLevel level) => _colorMap[level]!;

  static String badge(RiskLevel level) {
    switch (level) {
      case RiskLevel.bajo:
        return 'Bajo Riesgo';
      case RiskLevel.medio:
        return 'Riesgo medio';
      case RiskLevel.alto:
        return 'Riesgo alto';
    }
  }

  static TextStyle highlighted({
    required RiskLevel level,
    double fontSize = 18,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color(level),
    );
  }

  static RiskLevel fromFace(FaceLevel level) {
    switch (level) {
      case FaceLevel.sin:
        return RiskLevel.bajo;
      case FaceLevel.leve:
        return RiskLevel.medio;
      case FaceLevel.fuerte:
        return RiskLevel.alto;
    }
  }

  static RiskLevel fromSpeech(SpeechLevel level) {
    switch (level) {
      case SpeechLevel.sin:
        return RiskLevel.bajo;
      case SpeechLevel.leve:
        return RiskLevel.medio;
      case SpeechLevel.fuerte:
        return RiskLevel.alto;
    }
  }

  static RiskLevel fromArms(bool dropDetected) {
    return dropDetected ? RiskLevel.alto : RiskLevel.bajo;
  }
}
