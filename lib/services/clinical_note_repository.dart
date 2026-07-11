/// SmartBunda — Healthcare-professional clinical notes repository (Firestore).
library smartbunda.clinical_note_repository;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/clinical_note.dart';

class ClinicalNoteRepository {
  ClinicalNoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FS.consultations);

  /// Newest-first clinical notes for a patient (patient & staff views share it).
  Stream<List<ClinicalNote>> watchForPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClinicalNote.fromMap(d.id, d.data()))
            .toList());
  }

  /// Newest-first stream of ALL patients' clinical notes / consultations.
  /// Admin-only — the Firestore rules restrict reading the full collection to
  /// admins and clinical staff.
  Stream<List<ClinicalNote>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClinicalNote.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> add(ClinicalNote note) async {
    await _col.doc(note.id).set(note.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
