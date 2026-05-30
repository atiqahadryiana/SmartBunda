import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/services/appointment_repository.dart';

class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    final controller = StreamController<List<Appointment>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? patientSub;

    controller.onListen = () {
      patientSub = _firestore
          .collection(FS.appointments)
          .where('patientId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        final items = snapshot.docs.map((doc) => _fromMap(doc.data())).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        controller.add(items);
      });
    };

    controller.onCancel = () async {
      await patientSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<Appointment>> watchAllAppointments() {
    return _firestore
        .collection(FS.appointments)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
    });
  }

  @override
  Future<Appointment> scheduleAppointment(Appointment appointment) async {
    await _firestore
        .collection(FS.appointments)
        .doc(appointment.id)
        .set(_toMap(appointment));
    return appointment;
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    await _firestore
        .collection(FS.appointments)
        .doc(appointment.id)
        .set(_toMap(appointment), SetOptions(merge: true));
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection(FS.appointments).doc(appointmentId).set(
      {'status': 'CANCELLED'},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> completeAppointment(String appointmentId) async {
    await _firestore.collection(FS.appointments).doc(appointmentId).set(
      {'status': 'COMPLETED'},
      SetOptions(merge: true),
    );
  }

  @override
  Map<String, dynamic> exportState() => {};

  @override
  void restoreState(Map<String, dynamic> data) {}

  Map<String, dynamic> _toMap(Appointment appointment) {
    return {
      'id': appointment.id,
      'patientId': appointment.patientId,
      'providerId': appointment.providerId,
      'dateTime': appointment.dateTime.toIso8601String(),
      'type': appointment.type,
      'status': appointment.status,
    };
  }

  Appointment _fromMap(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      dateTime: _asDate(json['dateTime']) ?? DateTime.now(),
      type: json['type'] as String? ?? 'Consultation',
      status: json['status'] as String? ?? 'SCHEDULED',
    );
  }

  DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
