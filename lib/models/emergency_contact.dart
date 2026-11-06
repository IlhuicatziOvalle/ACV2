class EmergencyContact {
  final int? id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
