enum AlertSeverity { low, medium, high }

enum AlertType { deficiencyAlert, dietAdvice, reminder, appointment, system, nutrition }

class AlertItem {
  AlertItem({
    required this.id,
    required this.message,
    required this.severity,
    required this.type,
    required this.createdAt,
    this.status = 'SENT',
    required this.userId,
  });

  final String id;
  final String userId;
  final String message;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime createdAt;
  final String status;

  AlertItem copyWith({
    String? id,
    String? userId,
    String? message,
    AlertSeverity? severity,
    AlertType? type,
    DateTime? createdAt,
    String? status,
  }) {
    return AlertItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': userId,
      'message': message,
      'severity': severity.name.toUpperCase(),
      'type': _typeToString(type),
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String,
      userId: json['patientId'] as String? ?? json['userId'] as String? ?? '',
      message: json['message'] as String,
      severity: _severityFromString(json['severity'] as String?),
      type: _typeFromString(json['type'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'SENT',
    );
  }

  static AlertSeverity _severityFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return AlertSeverity.low;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
      default:
        return AlertSeverity.medium;
    }
  }

  static AlertType _typeFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'deficiency_alert':
      case 'deficiencyalert':
        return AlertType.deficiencyAlert;
      case 'diet_advice':
      case 'dietadvice':
        return AlertType.dietAdvice;
      case 'reminder':
        return AlertType.reminder;
      case 'appointment':
        return AlertType.appointment;
      case 'system':
        return AlertType.system;
      case 'nutrition':
      default:
        return AlertType.nutrition;
    }
  }

  static String _typeToString(AlertType type) {
    switch (type) {
      case AlertType.deficiencyAlert:
        return 'DEFICIENCY_ALERT';
      case AlertType.dietAdvice:
        return 'DIET_ADVICE';
      case AlertType.reminder:
        return 'REMINDER';
      case AlertType.appointment:
        return 'APPOINTMENT';
      case AlertType.system:
        return 'SYSTEM';
      case AlertType.nutrition:
        return 'NUTRITION';
    }
  }
}
