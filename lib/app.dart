import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alerta_acv/core/routing/app_router.dart';
import 'package:alerta_acv/core/theme/app_theme.dart';
import 'package:alerta_acv/core/di/app_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(highContrastProvider);
    final theme = highContrast ? AppTheme.highContrastTheme() : AppTheme.lightTheme();

    return MaterialApp.router(
      title: 'Alerta ACV',
      theme: theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

