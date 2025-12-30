class BackupSnapshot {
  BackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.payload,
  });

  final String id;
  final DateTime createdAt;
  final String label;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'label': label,
      'payload': payload,
    };
  }

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    return BackupSnapshot(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      label: json['label'] as String,
      payload: (json['payload'] as Map).cast<String, dynamic>(),
    );
  }
}
