import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/models/test_result.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService _db = DatabaseService.instance;
  List<TestResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await _db.getAllTestResults();
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResult(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar resultado'),
        content: const Text('¿Estás seguro de que quieres eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteTestResult(id);
      _loadResults();
    }
  }

  // Helper para obtener el color según el nivel de riesgo
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'bajo':
        return Colors.green;
      case 'medio':
        return Colors.yellow;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper para obtener el color de un detalle específico
  Color _getDetailColor(String value) {
    final val = value.toLowerCase();
    if (val.contains('normal') || val.contains('negativo')) return Colors.green;
    if (val.contains('sospechoso') || val.contains('leve')) return Colors.yellow;
    if (val.contains('anormal') || val.contains('caída') || val.contains('alto')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(
        child: Text(
          'No hay pruebas registradas.',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          final riskColor = _getRiskColor(result.riskLevel);
          final dateFormatted = DateFormat('dd/MM/yyyy').format(result.date);
          final timeFormatted = DateFormat('HH:mm').format(result.date);

          return Card(
            // CAMBIO 1: Fondo azul clarito, sin sombra, bordes redondeados
            color: const Color(0xFFF3F7FA),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              // CAMBIO 2a: Símbolo de advertencia (info_outline) coloreado según riesgo
              leading: Icon(
                Icons.info_outline,
                size: 32,
                color: riskColor,
              ),
              // CAMBIO 2b: Riesgo en negritas
              title: Text(
                'RIESGO ${result.riskLevel.toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: riskColor,
                ),
              ),
              // CAMBIO 2c y 2d: Fecha abajo del riesgo, hora a la izquierda.
              // Nota: La flecha de expansión se mantiene a la derecha por convención de UX de Flutter,
              // pero la información de tiempo está claramente alineada a la izquierda.
              subtitle: Row(
                children: [
                  Text(
                    '$dateFormatted - $timeFormatted',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // CAMBIO 3a: Título DETALLES en negritas
                      const Text(
                        'DETALLES',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CAMBIO 3b y 3c: Cajas de texto para cada detalle
                      _buildDetailBox('HABLA', result.speechLevel, _getDetailColor(result.speechLevel)),
                      const SizedBox(height: 12),
                      _buildDetailBox('CARA', result.faceLevel, _getDetailColor(result.faceLevel)),
                      const SizedBox(height: 12),
                      _buildDetailBox(
                          'BRAZOS',
                          result.armDrop ? 'Caída detectada' : 'Normal',
                          _getDetailColor(result.armDrop ? 'Caída detectada' : 'Normal')
                      ),

                      const SizedBox(height: 24),
                      // Botón de eliminar estilizado
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _deleteResult(result.id!),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text(
                            'Eliminar registro',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget helper para construir las cajas de texto de los detalles
  Widget _buildDetailBox(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Etiqueta con ancho fijo para alineación perfecta
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // El "cuadro de texto" solicitado
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco para que resalte sobre el azul de la tarjeta
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}