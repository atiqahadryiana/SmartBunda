import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/backup_snapshot.dart';
import '../models/system_settings.dart';
import 'alert_repository.dart';
import 'appointment_repository.dart';
import 'auth_repository.dart';
import 'data_store.dart';
import 'food_catalog_repository.dart';
import 'nutrition_plan_repository.dart';

class SystemAdminRepository {
  SystemAdminRepository({
    required this.authRepository,
    required this.dataStore,
    required this.planRepository,
    required this.appointmentRepository,
    required this.alertRepository,
    required this.foodCatalogRepository,
    FirebaseFirestore? firestore,
  }) {
    _firestore = firestore;
    _settingsController = StreamController<SystemSettings>.broadcast(
      onListen: () => _settingsController.add(_settings),
    );
    _backupsController = StreamController<List<BackupSnapshot>>.broadcast(
      onListen: () => _backupsController.add(List.unmodifiable(_backups)),
    );
    if (_firestore != null) {
      _settingsSub = _firestore!
          .collection(FS.systemSettings)
          .doc(FS.globalSettingsDoc)
          .snapshots()
          .listen((doc) {
        final data = doc.data();
        if (data == null) return;
        _settings = SystemSettings.fromJson(data);
        _settingsController.add(_settings);
      });
    }
  }

  final AuthRepository authRepository;
  final DataStore dataStore;
  final NutritionPlanRepository planRepository;
  final AppointmentRepository appointmentRepository;
  final AlertRepository alertRepository;
  final FoodCatalogRepository foodCatalogRepository;
  FirebaseFirestore? _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;

  SystemSettings _settings = SystemSettings();
  final List<BackupSnapshot> _backups = [];
  late final StreamController<SystemSettings> _settingsController;
  late final StreamController<List<BackupSnapshot>> _backupsController;

  Stream<SystemSettings> watchSettings() => _settingsController.stream;

  Stream<List<BackupSnapshot>> watchBackups() => _backupsController.stream;

  SystemSettings get settings => _settings;

  Future<void> updateSettings(SystemSettings settings) async {
    _settings = settings;
    _settingsController.add(_settings);
    if (_firestore != null) {
      await _firestore!
          .collection(FS.systemSettings)
          .doc(FS.globalSettingsDoc)
          .set(_settings.toJson(), SetOptions(merge: true));
    }
  }

  Future<BackupSnapshot> createBackup({String? label}) async {
    final payload = {
      'auth': authRepository.exportState(),
      'dataStore': dataStore.exportState(),
      'plans': planRepository.exportState(),
      'appointments': appointmentRepository.exportState(),
      'alerts': alertRepository.exportState(),
      'foodCatalog': foodCatalogRepository.exportState(),
      'settings': _settings.toJson(),
    };
    final snapshot = BackupSnapshot(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      label: label ?? 'Backup ${_backups.length + 1}',
      payload: payload,
    );
    _backups.insert(0, snapshot);
    _backupsController.add(List.unmodifiable(_backups));
    return snapshot;
  }

  Future<void> restoreBackup(BackupSnapshot snapshot) async {
    final payload = snapshot.payload;
    authRepository.restoreState(
      (payload['auth'] as Map).cast<String, dynamic>(),
    );
    dataStore.restoreState(
      (payload['dataStore'] as Map).cast<String, dynamic>(),
    );
    planRepository.restoreState(
      (payload['plans'] as Map).cast<String, dynamic>(),
    );
    appointmentRepository.restoreState(
      (payload['appointments'] as Map).cast<String, dynamic>(),
    );
    alertRepository.restoreState(
      (payload['alerts'] as Map).cast<String, dynamic>(),
    );
    foodCatalogRepository.restoreState(
      (payload['foodCatalog'] as Map).cast<String, dynamic>(),
    );
    _settings = SystemSettings.fromJson(
      (payload['settings'] as Map).cast<String, dynamic>(),
    );
    _settingsController.add(_settings);
  }

  Future<void> deleteBackup(String id) async {
    _backups.removeWhere((backup) => backup.id == id);
    _backupsController.add(List.unmodifiable(_backups));
  }

  void dispose() {
    _settingsSub?.cancel();
    _settingsController.close();
    _backupsController.close();
  }
}
