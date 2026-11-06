import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  /// Envía SMS a un número específico usando url_launcher
  static Future<bool> sendSms(String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final encodedMessage = Uri.encodeComponent(message);
    
    final Uri smsUri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');
    
    if (await canLaunchUrl(smsUri)) {
      return await launchUrl(smsUri);
    } else {
      throw Exception('No se pudo enviar SMS a $phoneNumber');
    }
  }

  /// Obtiene la ubicación actual del dispositivo con timeout de 5s
  static Future<String> getCurrentLocation() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Ubicación no disponible (GPS desactivado)';
      }

      // Verificar permisos usando Geolocator directamente
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Ubicación no disponible (sin permiso)';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return 'Ubicación no disponible (permiso denegado permanentemente)';
      }

      // Obtener ubicación actual con timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (e) {
      return 'Ubicación no disponible: $e';
    }
  }

  /// Genera mensaje de emergencia con ubicación y hora
  static Future<String> generateEmergencyMessage() async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final location = await getCurrentLocation();
    
    return '''🚨 ALERTA DE EMERGENCIA - Posible ACV

Necesito ayuda inmediata.

📍 Ubicación: $location
🕐 Hora: $timeStr

Por favor, llama al 911 o acude a mi ubicación.

- Enviado por Alerta ACV''';
  }

  /// Envía SMS de emergencia a múltiples contactos con pausa entre envíos
  static Future<List<String>> sendEmergencySmsToMultiple(
    List<String> phoneNumbers,
  ) async {
    final message = await generateEmergencyMessage();
    final errors = <String>[];

    for (final number in phoneNumbers) {
      try {
        await sendSms(number, message);
        // Pequeña pausa entre SMS para evitar problemas
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        errors.add('Error enviando a $number: $e');
      }
    }

    return errors;
  }

  /// Solicita permisos necesarios para SMS y ubicación
  static Future<bool> requestPermissions() async {
    // SMS permission (Android only, iOS returns granted/restricted)
    await Permission.sms.request();
    
    // Location permission using Geolocator
    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse || result == LocationPermission.always;
    }
    
    return locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always;
  }
}
