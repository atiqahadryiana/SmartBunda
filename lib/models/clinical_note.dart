import 'package:cloud_firestore/cloud_firestore.dart';

/// SmartBunda — Healthcare Professional clinical note / consultation record.
///
/// Authored by a healthcare professional for a patient and surfaced read-only
/// in the patient's Medical Records. Stored in `FS.consultations` (the
/// Consultations collection already has matching security rules: readable by
/// the patient, the authoring professional, and staff; written by staff).
class ClinicalNote {
  const ClinicalNote({
    required this.id,
    required this.patientId,
    required this.professionalId,
    required this.professionalName,
    required this.clinicalNote,
    required this.createdAt,
    this.nutritionRecommendation,
    this.followUpInstruction,
  });

  final String id;
  final String patientId;
  final String professionalId;
  final String professionalName;

  /// Main clinical note text.
  final String clinicalNote;
  final String? nutritionRecommendation;
  final String? followUpInstruction;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'professionalId': professionalId,
        'professionalName': professionalName,
        'clinicalNote': clinicalNote,
        if (nutritionRecommendation != null)
          'nutritionRecommendation': nutritionRecommendation,
        if (followUpInstruction != null)
          'followUpInstruction': followUpInstruction,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ClinicalNote.fromMap(String id, Map<String, dynamic> data) {
    return ClinicalNote(
      id: (data['id'] as String?) ?? id,
      patientId: (data['patientId'] as String?) ?? '',
      professionalId: (data['professionalId'] as String?) ?? '',
      professionalName: (data['professionalName'] as String?) ?? 'Care team',
      clinicalNote: (data['clinicalNote'] as String?) ?? '',
      nutritionRecommendation: data['nutritionRecommendation'] as String?,
      followUpInstruction: data['followUpInstruction'] as String?,
      createdAt: _asDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
