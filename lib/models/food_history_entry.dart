import 'package:cloud_firestore/cloud_firestore.dart';

/// A single AI food-analysis event saved for the patient's history.
class FoodHistoryEntry {
  const FoodHistoryEntry({
    required this.historyId,
    required this.patientId,
    required this.foodName,
    required this.confidenceScore,
    required this.qualityScore,
    required this.calories,
    required this.analysisDate,
    this.imageUrl,
  });

  final String historyId;
  final String patientId;
  final String foodName;

  /// Recognition confidence 0–100.
  final int confidenceScore;

  /// Image quality 0–100.
  final int qualityScore;
  final int calories;
  final DateTime analysisDate;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {
        'historyId': historyId,
        'patientId': patientId,
        'foodName': foodName,
        'confidenceScore': confidenceScore,
        'qualityScore': qualityScore,
        'calories': calories,
        'analysisDate': analysisDate.toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  factory FoodHistoryEntry.fromMap(String id, Map<String, dynamic> data) {
    return FoodHistoryEntry(
      historyId: (data['historyId'] as String?) ?? id,
      patientId: (data['patientId'] as String?) ?? '',
      foodName: (data['foodName'] as String?) ?? 'Food',
      confidenceScore: (data['confidenceScore'] as num?)?.round() ?? 0,
      qualityScore: (data['qualityScore'] as num?)?.round() ?? 0,
      calories: (data['calories'] as num?)?.round() ?? 0,
      analysisDate: _asDate(data['analysisDate']) ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
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
