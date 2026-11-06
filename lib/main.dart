import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alerta_acv/app.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/device/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Solicitar todos los permisos necesarios al inicio
  await _requestPermissions();
  
  // Pre-inicializar el modelo de voz en background (no bloquea el inicio de la app)
  FastService().init();
  
  // Inicializar widget con datos por defecto
  WidgetService.updateWidget();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _requestPermissions() async {
  await [
    Permission.microphone,
    Permission.camera,
    Permission.phone,
    Permission.contacts,
    Permission.sms,
    Permission.location,
  ].request();
}
