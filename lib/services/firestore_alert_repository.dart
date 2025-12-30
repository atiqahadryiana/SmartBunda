import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/alert_item.dart';
import 'alert_repository.dart';

class FirestoreAlertRepository implements AlertRepository {
  FirestoreAlertRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<AlertItem>> watchAlerts(String userId) {
    return _firestore
        .collection(FS.alerts)
        .where('patientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
    });
  }

  @override
  Stream<List<AlertItem>> watchAllAlerts() {
    return _firestore
        .collection(FS.alerts)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
    });
  }

  @override
  Future<void> addAlert(AlertItem alert) async {
    await _firestore.collection(FS.alerts).doc(alert.id).set(_toMap(alert));
  }

  @override
  Future<void> replaceAlerts(String userId, List<AlertItem> alerts) async {
    final batch = _firestore.batch();
    final existing = await _firestore
        .collection(FS.alerts)
        .where('patientId', isEqualTo: userId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final alert in alerts) {
      batch.set(_firestore.collection(FS.alerts).doc(alert.id), _toMap(alert));
    }
    await batch.commit();
  }

  @override
  Future<void> acknowledge(String alertId) async {
    await _firestore.collection(FS.alerts).doc(alertId).set(
      {'status': 'READ'},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> clearForUser(String userId) async {
    final batch = _firestore.batch();
    final existing = await _firestore
        .collection(FS.alerts)
        .where('patientId', isEqualTo: userId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Map<String, dynamic> exportState() => {};

  @override
  void restoreState(Map<String, dynamic> data) {}

  Map<String, dynamic> _toMap(AlertItem alert) {
    return {
      'id': alert.id,
      'patientId': alert.userId,
      'message': alert.message,
      'severity': alert.severity.name.toUpperCase(),
      'type': alert.toJson()['type'],
      'createdAt': alert.createdAt,
      'status': alert.status,
    };
  }

  AlertItem _fromMap(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String? ?? '',
      userId: json['patientId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: _severityFromString(json['severity'] as String?),
      type: _typeFromString(json['type'] as String?),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'SENT',
    );
  }

  AlertSeverity _severityFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return AlertSeverity.low;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
      default:
        return AlertSeverity.medium;
    }
  }

  AlertType _typeFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'deficiency_alert':
      case 'deficiencyalert':
        return AlertType.deficiencyAlert;
      case 'diet_advice':
      case 'dietadvice':
        return AlertType.dietAdvice;
      case 'reminder':
        return AlertType.reminder;
      case 'appointment':
        return AlertType.appointment;
      case 'system':
        return AlertType.system;
      case 'nutrition':
      default:
        return AlertType.nutrition;
    }
  }

  DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
