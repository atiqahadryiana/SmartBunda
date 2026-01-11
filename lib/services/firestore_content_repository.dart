import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/firestore_doc.dart';

class FirestoreContentRepository {
  FirestoreContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<FirestoreDoc>> watchEducationContent({bool activeOnly = true}) {
    return _watchCollection(
      FS.educationContent,
      activeOnly: activeOnly,
    );
  }

  Stream<List<FirestoreDoc>> watchRecommendations({
    String? userId,
    bool activeOnly = true,
  }) {
    return _watchCollection(
      FS.recommendations,
      userId: userId,
      activeOnly: activeOnly,
    );
  }

  Stream<List<FirestoreDoc>> watchNotifications({
    String? userId,
    bool activeOnly = true,
  }) {
    return _watchCollection(
      FS.notifications,
      userId: userId,
      activeOnly: activeOnly,
    );
  }

  Stream<List<FirestoreDoc>> watchReports({String? userId}) {
    return _watchCollection(
      FS.reports,
      userId: userId,
    );
  }

  Future<void> upsertEducationContent({
    String? id,
    required String title,
    String? summary,
    String? body,
    bool isActive = true,
  }) async {
    final docRef = _firestore
        .collection(FS.educationContent)
        .doc(id ?? _firestore.collection(FS.educationContent).doc().id);
    final payload = <String, dynamic>{
      'title': title,
      if (summary != null) 'summary': summary,
      if (body != null) 'body': body,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> upsertRecommendation({
    String? id,
    required String text,
    String? patientId,
    bool isActive = true,
  }) async {
    final docRef = _firestore
        .collection(FS.recommendations)
        .doc(id ?? _firestore.collection(FS.recommendations).doc().id);
    final payload = <String, dynamic>{
      'recommendation': text,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _applyPatientId(payload, patientId);
    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> upsertNotification({
    String? id,
    required String title,
    String? message,
    String? patientId,
    bool isActive = true,
  }) async {
    final docRef = _firestore
        .collection(FS.notifications)
        .doc(id ?? _firestore.collection(FS.notifications).doc().id);
    final payload = <String, dynamic>{
      'title': title,
      if (message != null) 'message': message,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _applyPatientId(payload, patientId);
    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> saveReport({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final docRef = _firestore.collection(FS.reports).doc();
    final payload = Map<String, dynamic>.from(data)
      ..['id'] = docRef.id
      ..['patientId'] = patientId
      ..['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(payload);
  }

  Future<void> setActive({
    required String collection,
    required String id,
    required bool isActive,
  }) async {
    await _firestore.collection(collection).doc(id).set(
      {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteDoc({
    required String collection,
    required String id,
  }) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<FirestoreDoc>> _watchCollection(
    String collection, {
    String? userId,
    bool activeOnly = false,
  }) {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => FirestoreDoc(id: doc.id, data: doc.data()))
          .toList();
      final filtered = <FirestoreDoc>[];
      for (final doc in docs) {
        if (activeOnly && doc.data['isActive'] == false) continue;
        if (userId != null) {
          final data = doc.data;
          if (data['patientId'] != userId && data['userId'] != userId) {
            continue;
          }
        }
        filtered.add(doc);
      }
      filtered.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return filtered;
    });
  }

  void _applyPatientId(Map<String, dynamic> payload, String? patientId) {
    final trimmed = patientId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      payload['patientId'] = FieldValue.delete();
      payload['userId'] = FieldValue.delete();
    } else {
      payload['patientId'] = trimmed;
    }
  }
}
