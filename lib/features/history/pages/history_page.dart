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
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteTestResult(id);
      _loadResults();
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'bajo':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Historial de Pruebas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    'No hay pruebas registradas.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(result.date);
                    final riskColor = _getRiskColor(result.riskLevel);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: riskColor.withValues(alpha: 0.2),
                          child: Icon(Icons.history, color: riskColor),
                        ),
                        title: Text(
                          'Riesgo: ${result.riskLevel}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        subtitle: Text(dateStr),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Habla', result.speechLevel),
                                _buildDetailRow('Cara', result.faceLevel),
                                _buildDetailRow('Brazos', result.armDrop ? 'Caída detectada' : 'Normal'),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _deleteResult(result.id!),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
