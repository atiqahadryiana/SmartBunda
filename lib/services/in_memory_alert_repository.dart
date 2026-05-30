import 'dart:async';

import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/services/alert_repository.dart';

class InMemoryAlertRepository implements AlertRepository {
  final Map<String, AlertItem> _alertsById = {};
  final Map<String, StreamController<List<AlertItem>>> _userControllers = {};
  late final StreamController<List<AlertItem>> _allController;

  InMemoryAlertRepository() {
    _allController = StreamController<List<AlertItem>>.broadcast(
      onListen: _emitAll,
    );
  }

  @override
  Stream<List<AlertItem>> watchAlerts(String userId) {
    return (_userControllers[userId] ??=
            StreamController<List<AlertItem>>.broadcast(
              onListen: () => _emitUser(userId),
            ))
        .stream;
  }

  @override
  Stream<List<AlertItem>> watchAllAlerts() => _allController.stream;

  @override
  Future<void> addAlert(AlertItem alert) async {
    _alertsById[alert.id] = alert;
    _emitUser(alert.userId);
    _emitAll();
  }

  @override
  Future<void> replaceAlerts(String userId, List<AlertItem> alerts) async {
    _alertsById.removeWhere((_, value) => value.userId == userId);
    for (final alert in alerts) {
      _alertsById[alert.id] = alert;
    }
    _emitUser(userId);
    _emitAll();
  }

  @override
  Future<void> acknowledge(String alertId) async {
    final alert = _alertsById[alertId];
    if (alert == null) return;
    _alertsById[alertId] = alert.copyWith(status: 'READ');
    _emitUser(alert.userId);
    _emitAll();
  }

  @override
  Future<void> clearForUser(String userId) async {
    _alertsById.removeWhere((_, value) => value.userId == userId);
    _emitUser(userId);
    _emitAll();
  }

  @override
  Map<String, dynamic> exportState() {
    return {
      'alerts': _alertsById.values.map((a) => a.toJson()).toList(),
    };
  }

  @override
  void restoreState(Map<String, dynamic> data) {
    final raw = data['alerts'];
    if (raw is List) {
      _alertsById
        ..clear()
        ..addEntries(
          raw
              .whereType<Map>()
              .map((e) => AlertItem.fromJson(e.cast<String, dynamic>()))
              .map((alert) => MapEntry(alert.id, alert)),
        );
      _emitAll();
      final userIds = _alertsById.values.map((a) => a.userId).toSet();
      for (final userId in userIds) {
        _emitUser(userId);
      }
    }
  }

  void _emitUser(String userId) {
    _userControllers[userId]?.add(_alertsForUser(userId));
  }

  void _emitAll() {
    _allController.add(_alertsById.values.toList());
  }

  List<AlertItem> _alertsForUser(String userId) {
    return _alertsById.values.where((a) => a.userId == userId).toList();
  }

  void dispose() {
    for (final controller in _userControllers.values) {
      controller.close();
    }
    _allController.close();
  }
}
