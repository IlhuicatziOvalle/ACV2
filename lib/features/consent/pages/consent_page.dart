import 'package:flutter/material.dart';
import 'package:alerta_acv/models/app_consent.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/core/constants/app_constants.dart';
import 'package:alerta_acv/features/fast/pages/home_page.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _consentAccepted = false;
  bool _privacyAccepted = false;
  bool _saving = false;

  final DatabaseService _db = DatabaseService.instance;

  Future<void> _acceptAndContinue() async {
    if (!_consentAccepted || !_privacyAccepted) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final consent = AppConsent(
      informedConsentAccepted: true,
      privacyAccepted: true,
      acceptedAt: DateTime.now(),
      consentVersion: kConsentVersion,
      appName: kAppName,
      appVersion: kAppVersion,
    );

    await _db.saveConsent(consent);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consentimiento y privacidad'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consentimiento informado digital',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'La aplicación Alerta ACV es una herramienta de apoyo para la identificación temprana de signos compatibles con accidente cerebrovascular (ACV). No sustituye la valoración, diagnóstico ni tratamiento realizado por profesionales de la salud.',
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'He leído y acepto el consentimiento informado digital.',
                            ),
                            value: _consentAccepted,
                            onChanged: (value) {
                              setState(() {
                                _consentAccepted = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aviso de privacidad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Los datos personales utilizados por la aplicación serán tratados únicamente para el funcionamiento de sus características. La información generada por la aplicación se almacena localmente en este dispositivo.',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Uso exclusivo clínico-educativo. No utilizar con fines comerciales.',
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'He leído y acepto el aviso de privacidad.',
                            ),
                            value: _privacyAccepted,
                            onChanged: (value) {
                              setState(() {
                                _privacyAccepted = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_consentAccepted &&
                      _privacyAccepted &&
                      !_saving)
                      ? _acceptAndContinue
                      : null,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Aceptar y continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}