enum AppointmentStatus { scheduled, completed, cancelled }

class Appointment {
  Appointment({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.dateTime,
    required this.type,
    required this.status,
  });

  final String id;
  final String patientId;
  final String providerId;
  final DateTime dateTime;
  final String type;
  final String status;

  Appointment copyWith({
    String? id,
    String? patientId,
    String? providerId,
    DateTime? dateTime,
    String? type,
    String? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      providerId: providerId ?? this.providerId,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'providerId': providerId,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'status': status,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: (json['type'] as String?) ?? 'Consultation',
      status: (json['status'] as String?) ?? 'SCHEDULED',
    );
  }
}
