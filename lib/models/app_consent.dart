class AppConsent {
  final int? id;
  final bool informedConsentAccepted;
  final bool privacyAccepted;
  final DateTime acceptedAt;
  final String consentVersion;
  final String appName;
  final String appVersion;

  AppConsent({
    this.id,
    required this.informedConsentAccepted,
    required this.privacyAccepted,
    required this.acceptedAt,
    required this.consentVersion,
    required this.appName,
    required this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'informedConsentAccepted': informedConsentAccepted ? 1 : 0,
      'privacyAccepted': privacyAccepted ? 1 : 0,
      'acceptedAt': acceptedAt.toIso8601String(),
      'consentVersion': consentVersion,
      'appName': appName,
      'appVersion': appVersion,
    };
  }

  factory AppConsent.fromMap(Map<String, dynamic> map) {
    return AppConsent(
      id: map['id'],
      informedConsentAccepted:
      (map['informedConsentAccepted'] as int) == 1,
      privacyAccepted:
      (map['privacyAccepted'] as int) == 1,
      acceptedAt: DateTime.parse(map['acceptedAt']),
      consentVersion: map['consentVersion'],
      appName: map['appName'],
      appVersion: map['appVersion'],
    );
  }
}