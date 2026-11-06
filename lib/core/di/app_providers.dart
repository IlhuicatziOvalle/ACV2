import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el modo alto contraste

final highContrastProvider = StateProvider<bool>((ref) => false);

/// Provider para el envío automático de SMS a contactos de emergencia
final autoSmsProvider = StateProvider<bool>((ref) => true);

/// Provider para habilitar/deshabilitar instrucciones habladas
final voicePromptsProvider = StateProvider<bool>((ref) => false);

