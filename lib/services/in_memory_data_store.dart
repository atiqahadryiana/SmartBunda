import 'dart:async';
import 'dart:math';

import '../models/feedback_entry.dart';
import '../models/food_entry.dart';
import '../models/hydration_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import 'data_store.dart';

class InMemoryDataStore implements DataStore {
  final Map<String, Profile> _profiles = {};
  final Map<String, Pregnancy> _pregnancies = {};
  final Map<String, List<FoodEntry>> _entries = {};
  final Map<String, List<HydrationEntry>> _hydration = {};
  final Map<String, List<FeedbackEntry>> _feedback = {};
  final _profileControllers = <String, StreamController<Profile?>>{};
  final _pregnancyControllers = <String, StreamController<Pregnancy?>>{};
  final _entryControllers = <String, StreamController<List<FoodEntry>>>{};
  final _hydrationControllers = <String, StreamController<List<HydrationEntry>>>{};
  final _feedbackControllers = <String, StreamController<List<FeedbackEntry>>>{};
  late final StreamController<Map<String, List<FoodEntry>>> _allEntriesController;
  late final StreamController<List<FeedbackEntry>> _allFeedbackController;
  late final StreamController<Map<String, Profile>> _allProfilesController;
  late final StreamController<Map<String, Pregnancy>> _allPregnanciesController;
  final _rand = Random();

  InMemoryDataStore() {
    _allEntriesController =
        StreamController<Map<String, List<FoodEntry>>>.broadcast(
      onListen: _emitAllEntries,
    );
    _allProfilesController = StreamController<Map<String, Profile>>.broadcast(
      onListen: _emitAllProfiles,
    );
    _allPregnanciesController =
        StreamController<Map<String, Pregnancy>>.broadcast(
      onListen: _emitAllPregnancies,
    );
    _allFeedbackController = StreamController<List<FeedbackEntry>>.broadcast(
      onListen: _emitAllFeedback,
    );
  }

  @override
  Stream<Profile?> watchProfile(String userId) {
    return (_profileControllers[userId] ??=
            StreamController<Profile?>.broadcast(
              onListen: () => _emitProfile(userId),
            ))
        .stream;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    _profiles[profile.patientId] = profile;
    _emitProfile(profile.patientId);
    _emitAllProfiles();
  }

  void _emitProfile(String userId) {
    _profileControllers[userId]?.add(_profiles[userId]);
  }

  @override
  Stream<Map<String, Profile>> watchAllProfiles() =>
      _allProfilesController.stream;

  void _emitAllProfiles() {
    _allProfilesController.add(Map.unmodifiable(_profiles));
  }

  @override
  Stream<Pregnancy?> watchPregnancy(String patientId) {
    return (_pregnancyControllers[patientId] ??=
            StreamController<Pregnancy?>.broadcast(
              onListen: () => _emitPregnancy(patientId),
            ))
        .stream;
  }

  @override
  Future<void> savePregnancy(Pregnancy pregnancy) async {
    _pregnancies[pregnancy.patientId] = pregnancy;
    _emitPregnancy(pregnancy.patientId);
    _emitAllPregnancies();
  }

  void _emitPregnancy(String patientId) {
    _pregnancyControllers[patientId]?.add(_pregnancies[patientId]);
  }

  @override
  Stream<Map<String, Pregnancy>> watchAllPregnancies() =>
      _allPregnanciesController.stream;

  void _emitAllPregnancies() {
    _allPregnanciesController.add(Map.unmodifiable(_pregnancies));
  }

  @override
  Stream<List<FoodEntry>> watchEntries(String userId) {
    return (_entryControllers[userId] ??=
            StreamController<List<FoodEntry>>.broadcast(
              onListen: () => _emitEntries(userId),
            ))
        .stream;
  }

  @override
  Future<void> addEntry(FoodEntry entry) async {
    final list = _entries.putIfAbsent(entry.userId, () => []);
    list.add(entry);
    _emitEntries(entry.userId);
  }

  @override
  Stream<Map<String, List<FoodEntry>>> watchAllEntries() =>
      _allEntriesController.stream;

  void _emitEntries(String userId) {
    _entryControllers[userId]?.add(List.unmodifiable(_entries[userId] ?? []));
    _emitAllEntries();
  }

  void _emitAllEntries() {
    _allEntriesController.add(Map.unmodifiable(_entries));
  }

  @override
  Stream<List<HydrationEntry>> watchHydrationEntries(String userId) {
    return (_hydrationControllers[userId] ??=
            StreamController<List<HydrationEntry>>.broadcast(
              onListen: () => _emitHydration(userId),
            ))
        .stream;
  }

  @override
  Future<void> addHydrationEntry(HydrationEntry entry) async {
    final list = _hydration.putIfAbsent(entry.userId, () => []);
    list.add(entry);
    _emitHydration(entry.userId);
  }

  void _emitHydration(String userId) {
    _hydrationControllers[userId]?.add(List.unmodifiable(_hydration[userId] ?? []));
  }

  @override
  Stream<List<FeedbackEntry>> watchFeedback(String userId) {
    return (_feedbackControllers[userId] ??=
            StreamController<List<FeedbackEntry>>.broadcast(
              onListen: () => _emitFeedback(userId),
            ))
        .stream;
  }

  @override
  Stream<List<FeedbackEntry>> watchAllFeedback() => _allFeedbackController.stream;

  @override
  Future<void> addFeedback(FeedbackEntry entry) async {
    final list = _feedback.putIfAbsent(entry.userId, () => []);
    list.add(entry);
    _emitFeedback(entry.userId);
  }

  void _emitFeedback(String userId) {
    _feedbackControllers[userId]?.add(List.unmodifiable(_feedback[userId] ?? []));
    _emitAllFeedback();
  }

  void _emitAllFeedback() {
    final all = _feedback.values.expand((entries) => entries).toList();
    _allFeedbackController.add(List.unmodifiable(all));
  }

  String newId() => (_rand.nextInt(9000000) + 1000000).toString();

  @override
  Map<String, dynamic> exportState() {
    return {
      'profiles': _profiles.values.map(_profileToJson).toList(),
      'pregnancies': _pregnancies.values.map(_pregnancyToJson).toList(),
      'entries': _entries.values.expand((e) => e).map(_entryToJson).toList(),
      'hydration': _hydration.values.expand((e) => e).map(_hydrationToJson).toList(),
      'feedback': _feedback.values.expand((e) => e).map(_feedbackToJson).toList(),
    };
  }

  @override
  void restoreState(Map<String, dynamic> data) {
    _profiles.clear();
    _pregnancies.clear();
    _entries.clear();
    _hydration.clear();
    _feedback.clear();

    final rawProfiles = data['profiles'];
    if (rawProfiles is List) {
      for (final raw in rawProfiles.whereType<Map>()) {
        final profile = _profileFromJson(raw.cast<String, dynamic>());
        _profiles[profile.patientId] = profile;
      }
    }

    final rawPregnancies = data['pregnancies'];
    if (rawPregnancies is List) {
      for (final raw in rawPregnancies.whereType<Map>()) {
        final pregnancy = _pregnancyFromJson(raw.cast<String, dynamic>());
        _pregnancies[pregnancy.patientId] = pregnancy;
      }
    }

    final rawEntries = data['entries'];
    if (rawEntries is List) {
      for (final raw in rawEntries.whereType<Map>()) {
        final entry = _entryFromJson(raw.cast<String, dynamic>());
        _entries.putIfAbsent(entry.userId, () => []).add(entry);
      }
    }

    final rawHydration = data['hydration'];
    if (rawHydration is List) {
      for (final raw in rawHydration.whereType<Map>()) {
        final entry = _hydrationFromJson(raw.cast<String, dynamic>());
        _hydration.putIfAbsent(entry.userId, () => []).add(entry);
      }
    }

    final rawFeedback = data['feedback'];
    if (rawFeedback is List) {
      for (final raw in rawFeedback.whereType<Map>()) {
        final entry = _feedbackFromJson(raw.cast<String, dynamic>());
        _feedback.putIfAbsent(entry.userId, () => []).add(entry);
      }
    }

    _emitAllProfiles();
    _emitAllPregnancies();
    for (final key in _profiles.keys) {
      _emitProfile(key);
    }
    for (final key in _pregnancies.keys) {
      _emitPregnancy(key);
    }
    for (final key in _entries.keys) {
      _emitEntries(key);
    }
    for (final key in _hydration.keys) {
      _emitHydration(key);
    }
    for (final key in _feedback.keys) {
      _emitFeedback(key);
    }
    _emitAllEntries();
    _emitAllFeedback();
  }

  Map<String, dynamic> _profileToJson(Profile profile) {
    return {
      'patientId': profile.patientId,
      'dob': profile.dob,
      'heightCm': profile.heightCm,
      'currentWeightKg': profile.currentWeightKg,
      'bloodType': profile.bloodType,
      'medicalConditions': profile.medicalConditions.map(_conditionToString).toList(),
      if (profile.conditionNotes != null) 'conditionNotes': profile.conditionNotes,
    };
  }

  Profile _profileFromJson(Map<String, dynamic> json) {
    return Profile(
      patientId: json['patientId'] as String,
      dob: json['dob'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
      bloodType: json['bloodType'] as String? ?? '',
      medicalConditions: _conditionsFromJson(json['medicalConditions']),
      conditionNotes: json['conditionNotes'] as String?,
    );
  }

  String _conditionToString(MedicalCondition condition) {
    switch (condition) {
      case MedicalCondition.anemia:
        return 'anemia';
      case MedicalCondition.gestationalDiabetes:
        return 'gestationalDiabetes';
    }
  }

  Set<MedicalCondition> _conditionsFromJson(dynamic raw) {
    if (raw is! List) return const <MedicalCondition>{};
    return raw
        .whereType<String>()
        .map((value) {
          switch (value.toLowerCase()) {
            case 'anemia':
            case 'anaemia':
              return MedicalCondition.anemia;
            case 'gestationaldiabetes':
              return MedicalCondition.gestationalDiabetes;
          }
          return null;
        })
        .whereType<MedicalCondition>()
        .toSet();
  }

  Map<String, dynamic> _pregnancyToJson(Pregnancy pregnancy) {
    return {
      'id': pregnancy.id,
      'patientId': pregnancy.patientId,
      'gestationalWeek': pregnancy.gestationalWeek,
      'trimester': pregnancy.trimester,
      'edd': pregnancy.edd,
      'riskLevel': pregnancy.riskLevel,
      'updatedAt': pregnancy.updatedAt?.toIso8601String(),
    };
  }

  Pregnancy _pregnancyFromJson(Map<String, dynamic> json) {
    return Pregnancy(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      gestationalWeek: (json['gestationalWeek'] as num?)?.toInt() ?? 0,
      trimester: (json['trimester'] as num?)?.toInt() ?? 0,
      edd: json['edd'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '',
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> _entryToJson(FoodEntry entry) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'logId': entry.logId,
      'foodId': entry.foodId,
      'date': entry.date.toIso8601String(),
      'meal': entry.meal,
      'quantity': entry.quantity,
      'unit': entry.unit,
      'calories': entry.calories,
      'protein': entry.protein,
      'carbs': entry.carbs,
      'fat': entry.fat,
      'ironMg': entry.ironMg,
      'folateMcg': entry.folateMcg,
      'notes': entry.notes,
      'mealType': entry.mealType,
    };
  }

  FoodEntry _entryFromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      logId: json['logId'] as String? ?? '',
      foodId: json['foodId'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      meal: json['meal'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'serving',
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      ironMg: (json['ironMg'] as num?)?.toDouble() ?? 0,
      folateMcg: (json['folateMcg'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      mealType: json['mealType'] as String?,
    );
  }

  Map<String, dynamic> _hydrationToJson(HydrationEntry entry) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'date': entry.date.toIso8601String(),
      'amountMl': entry.amountMl,
    };
  }

  HydrationEntry _hydrationFromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      amountMl: (json['amountMl'] as num).toInt(),
    );
  }

  Map<String, dynamic> _feedbackToJson(FeedbackEntry entry) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'userName': entry.userName,
      'message': entry.message,
      'createdAt': entry.createdAt.toIso8601String(),
      'rating': entry.rating,
    };
  }

  FeedbackEntry _feedbackFromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rating: (json['rating'] as num?)?.toInt(),
    );
  }

  void dispose() {
    for (final c in _profileControllers.values) {
      c.close();
    }
    for (final c in _pregnancyControllers.values) {
      c.close();
    }
    for (final c in _entryControllers.values) {
      c.close();
    }
    for (final c in _hydrationControllers.values) {
      c.close();
    }
    for (final c in _feedbackControllers.values) {
      c.close();
    }
    _allEntriesController.close();
    _allProfilesController.close();
    _allPregnanciesController.close();
    _allFeedbackController.close();
  }
}
