/// SmartBunda — Digital Assessment results repository (Firestore).
library smartbunda.assessment_result_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/assessment_result.dart';

class AssessmentResultRepository {
  AssessmentResultRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FS.assessmentResults);

  /// Newest-first stream of a patient's saved assessment results.
  Stream<List<AssessmentResult>> watchForPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AssessmentResult.fromMap(d.id, d.data()))
            .toList());
  }

  /// Newest-first stream of ALL patients' assessment results. Admin-only — the
  /// Firestore rules restrict reading the full collection to admins.
  Stream<List<AssessmentResult>> watchAll() {
    return _col
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AssessmentResult.fromMap(d.id, d.data()))
            .toList());
  }

  /// Persist a result. Uses [AssessmentResult.id] as the document id so saves
  /// are idempotent.
  Future<void> save(AssessmentResult result) async {
    await _col.doc(result.id).set(result.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
