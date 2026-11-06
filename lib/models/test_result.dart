class TestResult {
  final int? id;
  final DateTime date;
  final String speechLevel;
  final String faceLevel;
  final bool armDrop;
  final String riskLevel;

  TestResult({
    this.id,
    required this.date,
    required this.speechLevel,
    required this.faceLevel,
    required this.armDrop,
    required this.riskLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'speechLevel': speechLevel,
      'faceLevel': faceLevel,
      'armDrop': armDrop ? 1 : 0,
      'riskLevel': riskLevel,
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'],
      date: DateTime.parse(map['date']),
      speechLevel: map['speechLevel'],
      faceLevel: map['faceLevel'],
      armDrop: (map['armDrop'] as int) == 1,
      riskLevel: map['riskLevel'],
    );
  }
}
