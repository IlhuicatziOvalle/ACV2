import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/phone_utils.dart';
import 'package:alerta_acv/services/sms_service.dart';
import 'package:alerta_acv/widgets/countdown_dialog.dart';

/// Botón flotante permanente para llamar al 911
class Floating911Button extends StatelessWidget {
  const Floating911Button({super.key});

  Future<void> _call911(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownDialog(
        seconds: 10,
        onComplete: () => _executeEmergencyProtocol(context),
      ),
    );
  }

  Future<void> _executeEmergencyProtocol(BuildContext context) async {
    // 1. Llamar al 911 usando la integración nativa (Android/iOS)
    try {
      final fastService = FastService();
      final success = await fastService.placeCall911();

      // Fallback: si por alguna razón la llamada nativa falla, abrir marcador
      if (!success && context.mounted) {
        await PhoneUtils.launchDialer(context, '911');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al llamar al 911: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // 2. Enviar SMS a contactos de emergencia solo si el toggle está activado
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Consumer(
        builder: (_, ref, _) {
          final autoSms = ref.watch(autoSmsProvider);
          if (autoSms) {
            () async {
              try {
                final contacts = await DatabaseService.instance.getAllContacts();
                if (contacts.isNotEmpty) {
                  final phoneNumbers = contacts.map((c) => c.phoneNumber).toList();
                  final errors = await SmsService.sendEmergencySmsToMultiple(phoneNumbers);
                  if (context.mounted && errors.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SMS de emergencia enviado a tus contactos'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error enviando SMS: $e');
              }
            }();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _call911(context),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.phone),
      label: const Text(
        '911',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      tooltip: 'Llamar al 911',
    );
  }
}
