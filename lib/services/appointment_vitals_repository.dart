/// SmartBunda — per-appointment clinical vitals repository (Firestore).
library smartbunda.appointment_vitals_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/appointment_vitals.dart';

class AppointmentVitalsRepository {
  AppointmentVitalsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FS.appointmentVitals);

  /// Newest-first vitals history for a patient (visit-by-visit trend).
  Stream<List<AppointmentVitals>> watchForPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentVitals.fromMap(d.id, d.data()))
            .toList());
  }

  /// One-shot read of the latest vitals for a patient (null if none).
  Future<AppointmentVitals?> latestForPatient(String patientId) async {
    final snap = await _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return AppointmentVitals.fromMap(doc.id, doc.data());
  }

  Future<void> add(AppointmentVitals vitals) async {
    await _col.doc(vitals.id).set(vitals.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
