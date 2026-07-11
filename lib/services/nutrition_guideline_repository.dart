/// SmartBunda — Nutrition guideline repository (Firestore).
///
/// Stores admin-uploaded [NutritionGuideline]s and tracks which version is
/// active. The AI food-recommendation engine reads the active guideline as its
/// highest-priority source; when none is active it falls back to the built-in
/// [NutritionGuideline.maternalDefault].
library smartbunda.nutrition_guideline_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/nutrition_guideline.dart';

/// A stored guideline plus its activation state.
class StoredGuideline {
  const StoredGuideline({
    required this.docId,
    required this.guideline,
    required this.isActive,
    required this.updatedAt,
  });

  final String docId;
  final NutritionGuideline guideline;
  final bool isActive;
  final DateTime? updatedAt;
}

class NutritionGuidelineRepository {
  NutritionGuidelineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FS.nutritionGuidelines);

  Stream<List<StoredGuideline>> watchAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        return StoredGuideline(
          docId: d.id,
          guideline: NutritionGuideline.fromMap(data),
          isActive: data['isActive'] == true,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList()
        ..sort((a, b) => (b.updatedAt ?? DateTime(0))
            .compareTo(a.updatedAt ?? DateTime(0)));
      return list;
    });
  }

  /// The currently active guideline, or null if none is active.
  Stream<NutritionGuideline?> watchActive() {
    return _col
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : NutritionGuideline.fromMap(snap.docs.first.data()));
  }

  Future<void> upsert(NutritionGuideline guideline,
      {bool activate = false}) async {
    final docId = guideline.version;
    await _col.doc(docId).set({
      ...guideline.toMap(),
      'isActive': activate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (activate) await setActive(docId);
  }

  /// Activate one guideline version and deactivate all others (single active).
  Future<void> setActive(String docId) async {
    final all = await _col.get();
    final batch = _firestore.batch();
    for (final doc in all.docs) {
      batch.set(doc.reference, {'isActive': doc.id == docId},
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deactivate(String docId) async {
    await _col.doc(docId).set({'isActive': false}, SetOptions(merge: true));
  }

  Future<void> delete(String docId) async {
    await _col.doc(docId).delete();
  }
}
