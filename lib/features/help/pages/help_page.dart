import 'package:flutter/material.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ayuda'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Ayuda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildSection(
                title: '¿Qué es FAST?',
                content:
                    'FAST es un acrónimo que ayuda a identificar signos tempranos de un posible accidente cerebrovascular (ACV):\n\n'
                    '• F (Face - Cara): Asimetría facial\n'
                    '• A (Arms - Brazos): Debilidad en los brazos\n'
                    '• S (Speech - Habla): Dificultad para hablar\n'
                    '• T (Time - Tiempo): Es importante actuar rápido',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Importante',
                content:
                    'Esta aplicación NO proporciona un diagnóstico médico. '
                    'Es una herramienta educativa que puede ayudar a identificar posibles signos de ACV.\n\n'
                    'Ante cualquier duda o si detectas signos de ACV, llama inmediatamente al 911.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Cómo usar la app',
                content:
                    '1. Presiona "Iniciar prueba FAST"\n'
                    '2. Sigue las instrucciones en cada paso\n'
                    '3. La app evaluará los resultados\n'
                    '4. Si el riesgo es alto, se te ofrecerá llamar al 911 automáticamente\n\n'
                    'El botón 911 está siempre disponible en la esquina inferior derecha.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

