import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneUtils {
  static const _channel = MethodChannel('com.example.alerta_acv/call');
  
  static String normalizeNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static Future<void> launchDialer(BuildContext context, String phoneNumber) async {
    final normalized = normalizeNumber(phoneNumber);
    try {
      final success = await _channel.invokeMethod('makeCall', {'phoneNumber': normalized});
      if (success != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al intentar llamar')),
        );
      }
    }
  }
}
