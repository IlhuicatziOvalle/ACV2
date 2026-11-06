import 'package:flutter/material.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Ayuda',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ), //titulo de arriba de la pantalla
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             
              const SizedBox(height: 32),

              // CAMBIO 1: El warning ahora va hasta arriba con el estilo de HomePage
              const _WarningBanner(),

              const SizedBox(height: 24),

              // Las otras tarjetas con el nuevo estilo
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // CAMBIO 4: Fondo claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 20, // CAMBIO 2: Mismo tamaño que el warning
              height: 1.3,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// CAMBIO 3: Widget de warning con el mismo estilo que HomePage
class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF474E53),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start, // <-- Importante: mantiene el ícono alineado arriba
        children: [
          Icon(Icons.info_outline, size: 40, color: Color(0xFF1976D2)),
          SizedBox(width: 12), // <-- Un poco más de espacio para que respire con el título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMPORTANTE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold, // <-- Negritas
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4), // <-- Pequeña separación entre el título y el texto
                Text(
                  'Esta aplicación NO proporciona un diagnóstico médico. '
                      'Es una herramienta educativa que puede ayudar a identificar posibles signos de ACV.\n\n'
                      'Ante cualquier duda o si detectas signos de ACV, llama inmediatamente al 911.',
                  style: TextStyle(fontSize: 20, height: 1.3, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}