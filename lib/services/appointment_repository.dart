import 'package:smartbunda/models/appointment.dart';

abstract class AppointmentRepository {
  Stream<List<Appointment>> watchAppointmentsForUser(String userId);
  Stream<List<Appointment>> watchAllAppointments();
  Future<Appointment> scheduleAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> cancelAppointment(String appointmentId);
  Future<void> completeAppointment(String appointmentId);
  Map<String, dynamic> exportState();
  void restoreState(Map<String, dynamic> data);
}
