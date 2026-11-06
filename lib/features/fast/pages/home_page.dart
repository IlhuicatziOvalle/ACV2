import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';

import 'package:alerta_acv/services/device/widget_service.dart';

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
                        'Alerta ACV',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.push('/fast/face'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Iniciar prueba FAST',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _WarningBanner(),
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
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
        color: color.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta app no reemplaza una evaluación médica. En caso de duda, llama al 911.',
              style: TextStyle(fontSize: 13, height: 1.3),
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
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, bottom: 24),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.primary,
      onPressed: onTap,
      child: Icon(icon),
    );
  }
}

