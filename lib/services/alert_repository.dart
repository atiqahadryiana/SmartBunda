import 'package:smartbunda/models/alert_item.dart';

abstract class AlertRepository {
  Stream<List<AlertItem>> watchAlerts(String userId);
  Stream<List<AlertItem>> watchAllAlerts();
  Future<void> addAlert(AlertItem alert);
  Future<void> replaceAlerts(String userId, List<AlertItem> alerts);
  Future<void> acknowledge(String alertId);
  Future<void> clearForUser(String userId);
  Map<String, dynamic> exportState();
  void restoreState(Map<String, dynamic> data);
}
