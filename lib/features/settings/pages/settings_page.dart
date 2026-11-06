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
      backgroundColor: const Color.fromARGB(255, 243, 247, 250), //color de fondo de la pestaña
      appBar: AppBar( //barra de arriba
        backgroundColor: const Color.fromARGB(255, 243, 247, 250),//color de fondo de la barra
        // Reemplazamos la flecha automática por una personalizada
        leading: Center(
          child: Container(
          // Ajustamos el tamaño del círculo blanco
            width: 80,
            height: 80,
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco para que resalte
                shape: BoxShape.circle, // Forma circular
              ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 40),
              onPressed: () {
                Navigator.pop(context); // Acción para volver a la pantalla anterior
              },
            ),
          ),
        ),
        title: const Text('Ajustes',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ), //titulo de arriba de la pantalla
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Cambiado a SingleChildScrollView por si la pantalla es pequeña
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // CAMBIO 2: Se eliminó "Contactos de emergencia".
                // "Historial" ahora tiene su propia tarjeta con el nuevo estilo.
                Card(
                  color: Colors.white, // CAMBIO 1: Mismo azul clarito
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0, // Sin sombra para que coincida con el estilo limpio
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.history, size: 28, color: Colors.black87),
                    title: const Text(
                      'Historial de resultados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold, // CAMBIO 3: Negrita
                        color: Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 28, color: Colors.black87),
                    onTap: () => context.push('/history'),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle modo alto contraste con nuevo estilo
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: const Text(
                      'Modo alto contraste',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text(
                      'Aumenta el contraste para mejor visibilidad',
                      style: TextStyle(
                        fontSize: 20, // Mismo tamaño base
                        color: Colors.black87,
                      ),
                    ),
                    value: highContrast,
                    activeColor: const Color(0xFF1976D2), // Color del switch cuando está activo
                    onChanged: (value) {
                      ref.read(highContrastProvider.notifier).state = value;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // CAMBIO 2: Se eliminó por completo la tarjeta de "Envío automático de SMS"

                // Toggle Instrucciones habladas con nuevo estilo
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: const Text(
                      'Instrucciones habladas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text(
                      'Activa la voz que guía cada paso de la prueba',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    value: voicePrompts,
                    activeColor: const Color(0xFF1976D2),
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

                const SizedBox(height: 32), // Espacio final para que no quede pegado al borde
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}