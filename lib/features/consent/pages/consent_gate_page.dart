import 'package:flutter/material.dart';

import 'package:alerta_acv/core/constants/app_constants.dart';
import 'package:alerta_acv/features/consent/pages/consent_page.dart';
import 'package:alerta_acv/features/fast/pages/home_page.dart';
import 'package:alerta_acv/services/database_service.dart';

class ConsentGatePage extends StatefulWidget {
  const ConsentGatePage({super.key});

  @override
  State<ConsentGatePage> createState() => _ConsentGatePageState();
}

class _ConsentGatePageState extends State<ConsentGatePage> {
  final DatabaseService _db = DatabaseService.instance;

  bool? _hasConsent;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    try {
      final hasConsent =
      await _db.hasValidConsent(kConsentVersion);

      if (!mounted) return;

      setState(() {
        _hasConsent = hasConsent;
      });
    } catch (e) {
      debugPrint('Error checking consent: $e');

      if (!mounted) return;

      setState(() {
        _hasConsent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasConsent == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasConsent!) {
      return const HomePage();
    }

    return const ConsentPage();
  }
}