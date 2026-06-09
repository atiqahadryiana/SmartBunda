/// SmartBunda — Food analysis history repository (Firestore).
library smartbunda.food_history_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/food_history_entry.dart';

class FoodHistoryRepository {
  FoodHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<FoodHistoryEntry>> watchHistory(String patientId) {
    return _firestore
        .collection(FS.foodHistory)
        .where('patientId', isEqualTo: patientId)
        .orderBy('analysisDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodHistoryEntry.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> add(FoodHistoryEntry entry) async {
    await _firestore
        .collection(FS.foodHistory)
        .doc(entry.historyId)
        .set(entry.toMap());
  }
}
