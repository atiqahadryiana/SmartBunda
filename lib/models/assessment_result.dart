import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/models/assessment_catalog.dart';

/// A completed, saved digital-assessment result for a patient.
///
/// Persisted to `FS.assessmentResults`. Owned by [patientId] (matches the
/// owner-field convention used across the Firestore schema and security rules).
class AssessmentResult {
  const AssessmentResult({
    required this.id,
    required this.patientId,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.version,
    required this.score,
    required this.maxScore,
    required this.band,
    required this.summary,
    required this.recommendations,
    required this.answers,
    required this.completedAt,
  });

  final String id;
  final String patientId;
  final String assessmentId;
  final String assessmentTitle;
  final int version;
  final int score;
  final int maxScore;
  final RiskBand band;
  final String summary;
  final List<String> recommendations;

  /// questionId → selected option label (what the patient answered).
  final Map<String, String> answers;
  final DateTime completedAt;

  /// 0.0–1.0 — score as a fraction of the maximum possible.
  double get scoreFraction => maxScore == 0 ? 0 : score / maxScore;

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'assessmentId': assessmentId,
        'assessmentTitle': assessmentTitle,
        'version': version,
        'score': score,
        'maxScore': maxScore,
        'band': band.key,
        'bandLabel': band.label,
        'summary': summary,
        'recommendations': recommendations,
        'answers': answers,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  factory AssessmentResult.fromMap(String id, Map<String, dynamic> data) {
    return AssessmentResult(
      id: (data['id'] as String?) ?? id,
      patientId: (data['patientId'] as String?) ?? '',
      assessmentId: (data['assessmentId'] as String?) ?? '',
      assessmentTitle: (data['assessmentTitle'] as String?) ?? 'Assessment',
      version: (data['version'] as num?)?.toInt() ?? 1,
      score: (data['score'] as num?)?.toInt() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toInt() ?? 0,
      band: RiskBandX.fromKey(data['band'] as String?),
      summary: (data['summary'] as String?) ?? '',
      recommendations: (data['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      answers: (data['answers'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
      completedAt: _asDate(data['completedAt']) ?? DateTime.now(),
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
