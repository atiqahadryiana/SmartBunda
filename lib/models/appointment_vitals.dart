import 'package:cloud_firestore/cloud_firestore.dart';

/// SmartBunda — per-appointment clinical vitals snapshot.
///
/// Recorded by a nurse (or other staff) at each appointment so the patient's
/// key measurements (weight, hemoglobin, blood pressure, fundal height, …) are
/// captured visit-by-visit rather than only as a single overwritten profile
/// value. Stored in `FS.appointmentVitals` (the AppointmentVitals collection;
/// rules: patient reads own, staff read all and create/edit).
///
/// Optional fields are null when not measured at that visit; the UI shows "—".
class AppointmentVitals {
  const AppointmentVitals({
    required this.id,
    required this.patientId,
    required this.recordedBy,
    required this.recordedByName,
    required this.recordedAt,
    this.appointmentId,
    this.weightKg,
    this.hemoglobinGdl,
    this.systolicBp,
    this.diastolicBp,
    this.fundalHeightCm,
    this.gestationalWeek,
    this.notes,
  });

  final String id;
  final String patientId;

  /// UID of the staff member who recorded this (must equal the writer — audit).
  final String recordedBy;
  final String recordedByName;
  final DateTime recordedAt;

  /// Appointment this snapshot belongs to (null for an ad-hoc reading).
  final String? appointmentId;

  final double? weightKg;
  final double? hemoglobinGdl;
  final int? systolicBp;
  final int? diastolicBp;
  final double? fundalHeightCm;
  final int? gestationalWeek;
  final String? notes;

  /// "120/80" when both BP values are present, else null.
  String? get bloodPressure {
    if (systolicBp == null || diastolicBp == null) return null;
    return '$systolicBp/$diastolicBp';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'recordedBy': recordedBy,
        'recordedByName': recordedByName,
        'recordedAt': Timestamp.fromDate(recordedAt),
        if (appointmentId != null) 'appointmentId': appointmentId,
        if (weightKg != null) 'weightKg': weightKg,
        if (hemoglobinGdl != null) 'hemoglobinGdl': hemoglobinGdl,
        if (systolicBp != null) 'systolicBp': systolicBp,
        if (diastolicBp != null) 'diastolicBp': diastolicBp,
        if (fundalHeightCm != null) 'fundalHeightCm': fundalHeightCm,
        if (gestationalWeek != null) 'gestationalWeek': gestationalWeek,
        if (notes != null) 'notes': notes,
      };

  factory AppointmentVitals.fromMap(String id, Map<String, dynamic> data) {
    return AppointmentVitals(
      id: (data['id'] as String?) ?? id,
      patientId: (data['patientId'] as String?) ?? '',
      recordedBy: (data['recordedBy'] as String?) ?? '',
      recordedByName: (data['recordedByName'] as String?) ?? 'Care team',
      recordedAt: _asDate(data['recordedAt']) ?? DateTime.now(),
      appointmentId: data['appointmentId'] as String?,
      weightKg: _asDouble(data['weightKg']),
      hemoglobinGdl: _asDouble(data['hemoglobinGdl']),
      systolicBp: _asInt(data['systolicBp']),
      diastolicBp: _asInt(data['diastolicBp']),
      fundalHeightCm: _asDouble(data['fundalHeightCm']),
      gestationalWeek: _asInt(data['gestationalWeek']),
      notes: data['notes'] as String?,
    );
  }

  static DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static double? _asDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static int? _asInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
