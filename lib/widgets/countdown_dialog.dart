import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountdownDialog extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final String title;
  final String message;

  const CountdownDialog({
    super.key,
    this.seconds = 10,
    required this.onComplete,
    this.title = 'Llamada de Emergencia',
    this.message = 'Llamando al 911 en',
  });

  @override
  State<CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..forward();

    _startCountdown();
    _startVibration();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      // Vibración cada segundo
      HapticFeedback.heavyImpact();

      if (_remainingSeconds <= 0) {
        timer.cancel();
        Navigator.of(context).pop();
        widget.onComplete();
      }
    });
  }

  void _startVibration() {
    // Vibración inicial más larga
    HapticFeedback.vibrate();
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _animationController.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancelCountdown();
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de advertencia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Mensaje y contador
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Círculo de progreso con contador
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _animationController.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  '$_remainingSeconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cancelCountdown,
                icon: const Icon(Icons.close, size: 24),
                label: const Text(
                  'CANCELAR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
