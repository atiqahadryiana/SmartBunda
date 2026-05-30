import 'dart:async';

import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/services/appointment_repository.dart';

class InMemoryAppointmentRepository implements AppointmentRepository {
  final Map<String, Appointment> _appointmentsById = {};
  final Map<String, StreamController<List<Appointment>>> _userControllers = {};
  late final StreamController<List<Appointment>> _allController;

  InMemoryAppointmentRepository() {
    _allController = StreamController<List<Appointment>>.broadcast(
      onListen: _emitAll,
    );
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return (_userControllers[userId] ??=
            StreamController<List<Appointment>>.broadcast(
              onListen: () => _emitUser(userId),
            ))
        .stream;
  }

  @override
  Stream<List<Appointment>> watchAllAppointments() => _allController.stream;

  @override
  Future<Appointment> scheduleAppointment(Appointment appointment) async {
    _appointmentsById[appointment.id] = appointment;
    _emitUser(appointment.patientId);
    _emitUser(appointment.providerId);
    _emitAll();
    return appointment;
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    if (!_appointmentsById.containsKey(appointment.id)) {
      throw Exception('Appointment not found');
    }
    _appointmentsById[appointment.id] = appointment;
    _emitUser(appointment.patientId);
    _emitUser(appointment.providerId);
    _emitAll();
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final existing = _appointmentsById[appointmentId];
    if (existing == null) return;
    final updated = existing.copyWith(status: 'CANCELLED');
    _appointmentsById[appointmentId] = updated;
    _emitUser(updated.patientId);
    _emitUser(updated.providerId);
    _emitAll();
  }

  @override
  Future<void> completeAppointment(String appointmentId) async {
    final existing = _appointmentsById[appointmentId];
    if (existing == null) return;
    final updated = existing.copyWith(status: 'COMPLETED');
    _appointmentsById[appointmentId] = updated;
    _emitUser(updated.patientId);
    _emitUser(updated.providerId);
    _emitAll();
  }

  @override
  Map<String, dynamic> exportState() {
    return {
      'appointments': _appointmentsById.values.map((a) => a.toJson()).toList(),
    };
  }

  @override
  void restoreState(Map<String, dynamic> data) {
    final raw = data['appointments'];
    if (raw is List) {
      _appointmentsById
        ..clear()
        ..addEntries(
          raw
              .whereType<Map>()
              .map((e) => Appointment.fromJson(e.cast<String, dynamic>()))
              .map((appt) => MapEntry(appt.id, appt)),
        );
      _emitAll();
      final userIds = _appointmentsById.values
          .expand((appt) => [appt.patientId, appt.providerId])
          .toSet();
      for (final userId in userIds) {
        _emitUser(userId);
      }
    }
  }

  void _emitUser(String userId) {
    _userControllers[userId]?.add(_appointmentsForUser(userId));
  }

  void _emitAll() {
    _allController.add(_appointmentsById.values.toList());
  }

  List<Appointment> _appointmentsForUser(String userId) {
    return _appointmentsById.values
        .where((a) => a.patientId == userId || a.providerId == userId)
        .toList();
  }

  void dispose() {
    for (final controller in _userControllers.values) {
      controller.close();
    }
    _allController.close();
  }
}
