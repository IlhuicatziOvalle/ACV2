import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String _androidWidgetName = 'ACVWidgetProvider';

  /// Updates the widget with title and message
  static Future<void> updateWidget({
    String title = 'Alerta ACV',
    String message = 'Toca para abrir',
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('app_title', title);
      await HomeWidget.saveWidgetData<String>('app_message', message);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Checks if we should prompt the user to pin the widget
  static Future<void> checkAndPromptPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool promptShown = prefs.getBool('widget_prompt_shown') ?? false;

    if (!promptShown) {
      // Mark as shown immediately to avoid loop
      await prefs.setBool('widget_prompt_shown', true);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Acceso Rápido'),
            content: const Text(
              '¿Deseas agregar el widget de Alerta ACV a tu pantalla de inicio para acceso inmediato en emergencias?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Más tarde'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _requestPinWidget();
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<void> _requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error pinning widget: $e');
    }
  }
}
