/// SmartBunda — AI recommendation audit-trail repository (Firestore).
library smartbunda.recommendation_audit_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/recommendation_audit.dart';

class RecommendationAuditRepository {
  RecommendationAuditRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FS.recommendationAudit);

  Future<void> record(RecommendationAudit audit) async {
    await _col.doc(audit.id).set(audit.toMap());
  }

  /// Newest-first audit trail for a patient (for staff review).
  Stream<List<RecommendationAudit>> watchForPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RecommendationAudit.fromMap(d.id, d.data()))
            .toList());
  }
}
