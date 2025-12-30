import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/appointment.dart';
import 'appointment_repository.dart';

class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    final controller = StreamController<List<Appointment>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? patientSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? providerSub;
    List<Appointment> patientAppts = const [];
    List<Appointment> providerAppts = const [];

    void emit() {
      final byId = <String, Appointment>{};
      for (final appt in [...patientAppts, ...providerAppts]) {
        byId[appt.id] = appt;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      controller.add(merged);
    }

    controller.onListen = () {
      patientSub = _firestore
          .collection(FS.appointments)
          .where('patientId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        patientAppts = snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
        emit();
      });
      providerSub = _firestore
          .collection(FS.appointments)
          .where('providerId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        providerAppts = snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
        emit();
      });
    };

    controller.onCancel = () async {
      await patientSub?.cancel();
      await providerSub?.cancel();
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
