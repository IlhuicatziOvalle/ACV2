import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(highContrastProvider);
    final voicePrompts = ref.watch(voicePromptsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Ajustes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.contacts_outlined),
                      title: const Text('Contactos de emergencia'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/contacts'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Historial de resultados'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Toggle modo alto contraste
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Modo alto contraste',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Aumenta el contraste para mejor visibilidad',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: highContrast,
                  onChanged: (value) {
                    ref.read(highContrastProvider.notifier).state = value;
                    // El tema se actualizará automáticamente en app.dart
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Toggle SMS automático (ahora funcional)
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Envío automático de SMS',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Enviar SMS a contactos en caso de emergencia',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: ref.watch(autoSmsProvider),
                  onChanged: (value) {
                    ref.read(autoSmsProvider.notifier).state = value;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Envío automático de SMS ACTIVADO'
                            : 'Envío automático de SMS DESACTIVADO'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Instrucciones habladas',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Activa la voz que guía cada paso de la prueba',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: voicePrompts,
                  onChanged: (value) {
                    ref.read(voicePromptsProvider.notifier).state = value;
                    final message = value
                        ? 'Instrucciones habladas ACTIVADAS'
                        : 'Instrucciones habladas DESACTIVADAS';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

