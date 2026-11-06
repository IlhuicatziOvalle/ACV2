import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';

import 'package:alerta_acv/services/device/widget_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alerta_acv/core/di/app_providers.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/services/fast/fast_service.dart';
import 'package:alerta_acv/services/phone_utils.dart';
import 'package:alerta_acv/services/sms_service.dart';
import 'package:alerta_acv/widgets/countdown_dialog.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check for widget pin prompt after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetService.checkAndPromptPin(context);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const _PartnerLogos(),
                      const SizedBox(height: 24),
                      const Text(
                        'ALERTA ACV',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const _WarningBanner(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push('/fast/face'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Iniciar Prueba',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 80),
                        child: _HomeEmergencyButton(),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            const _UtilityButtons(),
          ],
        ),
      ),
    );
  }
}

class _PartnerLogos extends StatelessWidget {
  const _PartnerLogos();

  @override
  Widget build(BuildContext context) {
    const maxLogoHeight = 96.0;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: [
            _LogoTile(
              assetPath: 'assets/images/cruz_roja_tijuana_logo.png',
              semanticLabel: 'Cruz Roja Mexicana Tijuana',
              maxHeight: maxLogoHeight,
            ),
            _LogoTile(
              assetPath: 'assets/images/uabc_logo.png',
              semanticLabel: 'Universidad Autónoma de Baja California',
              maxHeight: maxLogoHeight,
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.assetPath,
    required this.semanticLabel,
    required this.maxHeight,
  });

  final String assetPath;
  final String semanticLabel;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Semantics(
        label: semanticLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Image.asset(
            assetPath,
            height: maxHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // color: color.secondaryContainer.withValues(alpha: 0.25),
        color: const Color(0xFF474E53),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, size: 40, color: Color(0xFF1976D2)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta app no reemplaza una evaluación médica. En caso de duda, llama al 911.',
              style: TextStyle(fontSize: 20, height: 1.3, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityButtons extends StatelessWidget {
  const _UtilityButtons();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniFab(
              icon: Icons.help_outline,
              tooltip: 'Ayuda',
              onTap: () => context.push('/help'),
            ),
            const SizedBox(height: 12),
            _MiniFab(
              icon: Icons.settings_outlined,
              tooltip: 'Ajustes',
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFab extends StatelessWidget {
  const _MiniFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: tooltip,
      tooltip: tooltip,
      backgroundColor: Color(0xFF393E42),
      foregroundColor: Colors.white,
      onPressed: onTap,
      child: Icon(icon),
    );
  }
}

class _HomeEmergencyButton extends ConsumerWidget {
  const _HomeEmergencyButton();

  Future<void> _call911(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownDialog(
        seconds: 10,
        onComplete: () => _executeEmergencyProtocol(context, ref),
      ),
    );
  }

  Future<void> _executeEmergencyProtocol(BuildContext context, WidgetRef ref) async {
    // 1. Llamar al 911
    try {
      final fastService = FastService();
      final success = await fastService.placeCall911();

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

    // 2. Enviar SMS a contactos de emergencia
    // ¡Aquí está la mejora! Usamos 'ref' directamente porque ya lo tenemos disponible.
    final autoSms = ref.read(autoSmsProvider);

    if (autoSms) {
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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      // Pasamos 'ref' a la función para que pueda usarlo después
      onPressed: () => _call911(context, ref),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        elevation: 6,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone, size: 40),
          SizedBox(width: 12),
          Text(
            '911',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}