import 'package:cloud_firestore/cloud_firestore.dart';

/// SmartBunda — AI food-recommendation audit record.
///
/// Written whenever a patient **accepts** (logs) an AI food recommendation, so
/// the decision is fully traceable for healthcare-professional review. Stores
/// the guideline version used, the signals the engine consulted, the reason
/// shown to the patient, the chosen food, and the serving the patient saved
/// (including any adjustment they made).
class RecommendationAudit {
  const RecommendationAudit({
    required this.id,
    required this.patientId,
    required this.foodName,
    required this.guidelineVersion,
    required this.guidelineSource,
    required this.reason,
    required this.signalsUsed,
    required this.recommendedServingG,
    required this.savedServingG,
    required this.calories,
    required this.proteinG,
    required this.ironMg,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String foodName;

  /// Guideline version applied (audit requirement).
  final String guidelineVersion;
  final String guidelineSource;

  /// Plain-language reason shown to the patient.
  final String reason;

  /// Priority signals the engine consulted (e.g. guideline, profile,
  /// assessment:nutrition_risk, mealHistory).
  final List<String> signalsUsed;

  final double recommendedServingG;

  /// Serving the user actually saved (captures user adjustment).
  final double savedServingG;
  final int calories;
  final int proteinG;
  final double ironMg;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'foodName': foodName,
        'guidelineVersion': guidelineVersion,
        'guidelineSource': guidelineSource,
        'reason': reason,
        'signalsUsed': signalsUsed,
        'recommendedServingG': recommendedServingG,
        'savedServingG': savedServingG,
        'userAdjustedServing': (savedServingG - recommendedServingG).abs() > 1,
        'calories': calories,
        'proteinG': proteinG,
        'ironMg': ironMg,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory RecommendationAudit.fromMap(String id, Map<String, dynamic> data) {
    return RecommendationAudit(
      id: (data['id'] as String?) ?? id,
      patientId: (data['patientId'] as String?) ?? '',
      foodName: (data['foodName'] as String?) ?? '',
      guidelineVersion: (data['guidelineVersion'] as String?) ?? '',
      guidelineSource: (data['guidelineSource'] as String?) ?? '',
      reason: (data['reason'] as String?) ?? '',
      signalsUsed: (data['signalsUsed'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedServingG:
          (data['recommendedServingG'] as num?)?.toDouble() ?? 0,
      savedServingG: (data['savedServingG'] as num?)?.toDouble() ?? 0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      proteinG: (data['proteinG'] as num?)?.toInt() ?? 0,
      ironMg: (data['ironMg'] as num?)?.toDouble() ?? 0,
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
