import 'package:go_router/go_router.dart';
import 'package:alerta_acv/features/fast/pages/face_step_page.dart';
import 'package:alerta_acv/features/fast/pages/arms_step_page.dart';
import 'package:alerta_acv/features/fast/pages/speech_step_page.dart';
import 'package:alerta_acv/features/fast/pages/decision_page.dart';
import 'package:alerta_acv/features/history/pages/history_page.dart';
import 'package:alerta_acv/features/contacts/pages/contacts_page.dart';
import 'package:alerta_acv/features/settings/pages/settings_page.dart';
import 'package:alerta_acv/features/help/pages/help_page.dart';
import 'package:alerta_acv/features/fast/pages/home_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/fast/face',
      builder: (context, state) => const FaceStepPage(),
    ),
    GoRoute(
      path: '/fast/arms',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ArmsStepPage(
          faceLevel: extra?['faceLevel'],
        );
      },
    ),
    GoRoute(
      path: '/fast/speech',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SpeechStepPage(
          faceLevel: extra?['faceLevel'],
          dropDetected: extra?['dropDetected'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/fast/decision',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DecisionPage(
          speechLevel: extra?['speechLevel'],
          faceLevel: extra?['faceLevel'],
          dropDetected: extra?['dropDetected'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpPage(),
    ),
  ],
);

