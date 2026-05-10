import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/feedback_entry.dart';
import '../models/food_entry.dart';
import '../models/hydration_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import 'data_store.dart';

class FirestoreDataStore implements DataStore {
  FirestoreDataStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<Profile?> watchProfile(String userId) {
    return _firestore
        .collection(FS.patientProfiles)
        .doc(userId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? _profileFromMap(doc.data()!, userId: doc.id) : null,
        );
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    await _firestore
        .collection(FS.patientProfiles)
        .doc(profile.patientId)
        .set(_profileToMap(profile), SetOptions(merge: true));
  }

  @override
  Stream<Map<String, Profile>> watchAllProfiles() {
    return _firestore
        .collection(FS.patientProfiles)
        .snapshots()
        .map((snapshot) {
      final map = <String, Profile>{};
      for (final doc in snapshot.docs) {
        final profile = _profileFromMap(doc.data(), userId: doc.id);
        map[profile.patientId] = profile;
      }
      return map;
    });
  }

  @override
  Stream<Pregnancy?> watchPregnancy(String patientId) {
    return _firestore
        .collection(FS.pregnancies)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final pregnancies = snapshot.docs
          .map((doc) => _pregnancyFromMap(doc.data(), docId: doc.id))
          .toList();
      return _latestPregnancy(pregnancies);
    });
  }

  @override
  Future<void> savePregnancy(Pregnancy pregnancy) async {
    await _firestore
        .collection(FS.pregnancies)
        .doc(pregnancy.id)
        .set(_pregnancyToMap(pregnancy), SetOptions(merge: true));
  }

  @override
  Stream<Map<String, Pregnancy>> watchAllPregnancies() {
    return _firestore.collection(FS.pregnancies).snapshots().map((snapshot) {
      final byPatient = <String, List<Pregnancy>>{};
      for (final doc in snapshot.docs) {
        final pregnancy = _pregnancyFromMap(doc.data(), docId: doc.id);
        final patientId = pregnancy.patientId;
        if (patientId.isEmpty) continue;
        byPatient.putIfAbsent(patientId, () => []).add(pregnancy);
      }
      final map = <String, Pregnancy>{};
      byPatient.forEach((patientId, list) {
        final latest = _latestPregnancy(list);
        if (latest != null) {
          map[patientId] = latest;
        }
      });
      return map;
    });
  }

  @override
  Stream<List<FoodEntry>> watchEntries(String userId) {
    final controller = StreamController<List<FoodEntry>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? daysSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? fallbackSub;
    final dayDates = <String, DateTime?>{};
    final dayEntryPaths = <String, Set<String>>{};
    final dayPaths = <String>{};
    final entriesByPath = <String, FoodEntry>{};
    final fallbackPaths = <String>{};
    final entrySubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

    void emit() {
      final entries = entriesByPath.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      controller.add(entries);
    }

    void subscribeDay(String dayId) {
      entrySubs[dayId]?.cancel();
      entrySubs[dayId] = _firestore
          .collection(FS.foodLogs)
          .doc(userId)
          .collection('Days')
          .doc(dayId)
          .collection('Entries')
          .snapshots()
          .listen((snapshot) {
        final previousPaths = dayEntryPaths[dayId];
        if (previousPaths != null) {
          for (final path in previousPaths) {
            dayPaths.remove(path);
            if (!fallbackPaths.contains(path)) {
              entriesByPath.remove(path);
            }
          }
        }
        final logDate = dayDates[dayId] ?? _parseDate(dayId);
        final newPaths = <String>{};
        for (final doc in snapshot.docs) {
          final path = doc.reference.path;
          newPaths.add(path);
          entriesByPath[path] = _entryFromLogEntryMap(
            doc.data(),
            id: doc.id,
            userId: userId,
            logDate: logDate,
          );
        }
        dayEntryPaths[dayId] = newPaths;
        dayPaths.addAll(newPaths);
        emit();
      });
    }

    void updateFallback(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final path in fallbackPaths) {
        if (!dayPaths.contains(path)) {
          entriesByPath.remove(path);
        }
      }
      fallbackPaths.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final resolvedUserId = _stringOrNull(data['patientId']) ??
            _stringOrNull(data['userId']) ??
            _userIdFromEntryRef(doc.reference);
        if (resolvedUserId != userId) {
          continue;
        }
        final path = doc.reference.path;
        fallbackPaths.add(path);
        final dayId = _dayIdFromEntryRef(doc.reference);
        final logDate = _parseDate(dayId) ?? _asDate(data['date']);
        entriesByPath[path] = _entryFromLogEntryMap(
          data,
          id: doc.id,
          userId: userId,
          logDate: logDate,
        );
      }
      emit();
    }

    controller.onListen = () {
      daysSub = _firestore
          .collection(FS.foodLogs)
          .doc(userId)
          .collection('Days')
          .snapshots()
          .listen((snapshot) {
        final dayIds = snapshot.docs.map((doc) => doc.id).toSet();
        for (final doc in snapshot.docs) {
          dayDates[doc.id] = _asDate(doc.data()['date']) ?? _parseDate(doc.id);
          if (!entrySubs.containsKey(doc.id)) {
            subscribeDay(doc.id);
          }
        }
        for (final dayId in entrySubs.keys.toList()) {
          if (!dayIds.contains(dayId)) {
            entrySubs.remove(dayId)?.cancel();
            final paths = dayEntryPaths.remove(dayId);
            if (paths != null) {
              for (final path in paths) {
                dayPaths.remove(path);
                if (!fallbackPaths.contains(path)) {
                  entriesByPath.remove(path);
                }
              }
            }
            dayDates.remove(dayId);
          }
        }
        emit();
      });
      fallbackSub = _firestore
          .collectionGroup('Entries')
          .where('patientId', isEqualTo: userId)
          .snapshots()
          .listen(updateFallback);
    };

    controller.onCancel = () async {
      await daysSub?.cancel();
      await fallbackSub?.cancel();
      for (final sub in entrySubs.values) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<void> addEntry(FoodEntry entry) async {
    final date = entry.date;
    final logDate = _formatDate(date);
    final logRef = _firestore.collection(FS.foodLogs).doc(entry.userId);
    final dayRef = logRef.collection('Days').doc(logDate);
    final itemRef = dayRef.collection('Entries').doc(entry.id);
    final logItemRef = _firestore
        .collection(FS.foodLogItems)
        .doc('${entry.userId}_${entry.id}');
    final batch = _firestore.batch();
    batch.set(
      logRef,
      {
        'patientId': entry.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      dayRef,
      {
        'date': logDate,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(itemRef, _entryToLogEntryMap(entry));
    batch.set(
      logItemRef,
      {
        ..._entryToLogEntryMap(entry),
        'userId': entry.userId,
        'entryId': entry.id,
        'dayId': logDate,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  @override
  Stream<Map<String, List<FoodEntry>>> watchAllEntries() {
    final controller =
        StreamController<Map<String, List<FoodEntry>>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? entriesSub;

    void emit(QuerySnapshot<Map<String, dynamic>> snapshot) {
      final byUser = <String, List<FoodEntry>>{};
      for (final doc in snapshot.docs) {
        final userId = _userIdFromEntryRef(doc.reference) ??
            _stringOrNull(doc.data()['patientId']) ??
            _stringOrNull(doc.data()['userId']);
        if (userId == null) continue;
        final dayId = _dayIdFromEntryRef(doc.reference);
        final logDate = _parseDate(dayId) ?? _asDate(doc.data()['date']);
        final entry = _entryFromLogEntryMap(
          doc.data(),
          id: doc.id,
          userId: userId,
          logDate: logDate,
        );
        byUser.putIfAbsent(userId, () => []).add(entry);
      }
      for (final entries in byUser.values) {
        entries.sort((a, b) => b.date.compareTo(a.date));
      }
      controller.add(byUser);
    }

    controller.onListen = () {
      entriesSub =
          _firestore.collectionGroup('Entries').snapshots().listen(emit);
    };

    controller.onCancel = () async {
      await entriesSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<HydrationEntry>> watchHydrationEntries(String userId) {
    return _firestore
        .collection(FS.hydrationLogs)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _hydrationFromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> addHydrationEntry(HydrationEntry entry) async {
    await _firestore
        .collection(FS.hydrationLogs)
        .doc(entry.id)
        .set(_hydrationToMap(entry));
  }

  @override
  Stream<List<FeedbackEntry>> watchFeedback(String userId) {
    return _firestore
        .collection(FS.feedback)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _feedbackFromMap(doc.data())).toList(),
        );
  }

  @override
  Stream<List<FeedbackEntry>> watchAllFeedback() {
    return _firestore
        .collection(FS.feedback)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _feedbackFromMap(doc.data())).toList(),
        );
  }

  @override
  Future<void> addFeedback(FeedbackEntry entry) async {
    await _firestore
        .collection(FS.feedback)
        .doc(entry.id)
        .set(_feedbackToMap(entry));
  }

  @override
  Map<String, dynamic> exportState() => {};

  @override
  void restoreState(Map<String, dynamic> data) {}

  Map<String, dynamic> _profileToMap(Profile profile) {
    return {
      'patientId': profile.patientId,
      'dob': profile.dob,
      'heightCm': profile.heightCm,
      'currentWeightKg': profile.currentWeightKg,
      'bloodType': profile.bloodType,
      'hemoglobinGdl': profile.hemoglobinGdl,
      'abdominalCircumferenceCm': profile.abdominalCircumferenceCm,
      'medicalConditions':
          profile.medicalConditions.map(_conditionToString).toList(),
      if (profile.conditionNotes != null)
        'conditionNotes': profile.conditionNotes,
    };
  }

  Profile _profileFromMap(Map<String, dynamic> json, {String? userId}) {
    return Profile(
      patientId: json['patientId'] as String? ?? userId ?? '',
      dob: json['dob'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
      bloodType: json['bloodType'] as String? ?? '',
      hemoglobinGdl: _doubleFrom(
        _firstNonNull([
          json['hemoglobinGdl'],
          json['haemoglobinGdl'],
          json['hemoglobin'],
          json['hemoglobins'],
          json['haemoglobin'],
          json['haemoglobins'],
          json['hbGdl'],
          json['hb'],
        ]),
      ),
      abdominalCircumferenceCm: _doubleFrom(
        _firstNonNull([
          json['abdominalCircumferenceCm'],
          json['stomachCircumferenceCm'],
          json['abdomenCircumferenceCm'],
          json['abdominalCircumference'],
          json['stomachCircumference'],
          json['circumferenceOfStomach'],
        ]),
      ),
      medicalConditions: _conditionsFromJson(json['medicalConditions']),
      conditionNotes: _stringOrNull(json['conditionNotes']),
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

  Map<String, dynamic> _pregnancyToMap(Pregnancy pregnancy) {
    return {
      'pregnancyId': pregnancy.id,
      'patientId': pregnancy.patientId,
      'gestationalWeek': pregnancy.gestationalWeek,
      'trimester': pregnancy.trimester,
      'edd': pregnancy.edd,
      'riskLevel': pregnancy.riskLevel,
      'updatedAt': pregnancy.updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  Pregnancy _pregnancyFromMap(Map<String, dynamic> json, {String? docId}) {
    return Pregnancy(
      id: json['pregnancyId'] as String? ??
          json['id'] as String? ??
          docId ??
          '',
      patientId: json['patientId'] as String? ?? '',
      gestationalWeek: (json['gestationalWeek'] as num?)?.toInt() ?? 0,
      trimester: (json['trimester'] as num?)?.toInt() ?? 0,
      edd: json['edd'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '',
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Pregnancy? _latestPregnancy(List<Pregnancy> pregnancies) {
    if (pregnancies.isEmpty) return null;
    pregnancies.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeCompare = bTime.compareTo(aTime);
      if (timeCompare != 0) return timeCompare;
      return b.gestationalWeek.compareTo(a.gestationalWeek);
    });
    return pregnancies.first;
  }

  Map<String, dynamic> _entryToLogEntryMap(FoodEntry entry) {
    return {
      'patientId': entry.userId,
      'foodId': entry.foodId,
      'meal': entry.meal,
      'foodName': entry.meal,
      'loggedAt': entry.date,
      'portion': _portionLabel(entry.quantity, entry.unit),
      'quantity': entry.quantity,
      'unit': entry.unit,
      'calories': entry.calories,
      'nutrients': {
        'protein_g': entry.protein,
        'carb_g': entry.carbs,
        'fat_g': entry.fat,
        'iron_mg': entry.ironMg,
        'folate_mcg': entry.folateMcg,
      },
      'source': entry.foodId == 'MANUAL' ? 'manual' : 'catalog',
      'mealType': entry.mealType ?? _mealTypeFromDate(entry.date),
    };
  }

  FoodEntry _entryFromLogEntryMap(
    Map<String, dynamic> json, {
    required String id,
    required String userId,
    DateTime? logDate,
  }) {
    final nutrients =
        (json['nutrients'] as Map?)?.cast<String, dynamic>() ?? {};
    final portion = _stringOrNull(json['portion']) ??
        _stringOrNull(json['serving']) ??
        _stringOrNull(json['servingSize']);
    final meal = _stringOrNull(json['meal']) ??
        _stringOrNull(json['foodName']) ??
        _stringOrNull(json['name']) ??
        'Meal';
    final date = _asDate(json['loggedAt']) ??
        _asDate(json['date']) ??
        logDate ??
        DateTime.now();
    final mealType = _stringOrNull(json['mealType']) ??
        _stringOrNull(json['meal_type']) ??
        _mealTypeFromDate(date);
    return FoodEntry(
      id: id,
      userId: userId,
      logId: _stringOrNull(json['logId']) ?? '',
      foodId:
          _stringOrNull(json['foodId']) ?? _stringOrNull(json['source']) ?? '',
      date: date,
      meal: meal,
      quantity:
          _doubleFrom(json['quantity']) ?? _quantityFromPortion(portion) ?? 1,
      unit: _stringOrNull(json['unit']) ?? _unitFromPortion(portion) ?? '',
      calories: _intFrom(
            _firstNonNull([
              json['calories'],
              json['caloriesPerServing'],
              json['calories_per_serving'],
              nutrients['calories'],
            ]),
          ) ??
          0,
      protein: _intFrom(
            _firstNonNull([
              nutrients['protein_g'],
              nutrients['protein'],
              json['proteinG'],
              json['protein_g'],
              json['protein'],
            ]),
          ) ??
          0,
      carbs: _intFrom(
            _firstNonNull([
              nutrients['carb_g'],
              nutrients['carbs'],
              nutrients['carb'],
              json['carbG'],
              json['carb_g'],
              json['carbs'],
              json['carb'],
            ]),
          ) ??
          0,
      fat: _intFrom(
            _firstNonNull([
              nutrients['fat_g'],
              nutrients['fat'],
              json['fatG'],
              json['fat_g'],
              json['fat'],
            ]),
          ) ??
          0,
      ironMg: _doubleFrom(
            _firstNonNull([
              nutrients['iron_mg'],
              nutrients['iron'],
              json['ironMg'],
              json['iron_mg'],
              json['iron'],
            ]),
          ) ??
          0,
      folateMcg: _doubleFrom(
            _firstNonNull([
              nutrients['folate_mcg'],
              nutrients['folate'],
              json['folateMcg'],
              json['folate_mcg'],
              json['folate'],
            ]),
          ) ??
          0,
      mealType: mealType,
    );
  }

  Map<String, dynamic> _hydrationToMap(HydrationEntry entry) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'date': entry.date,
      'amountMl': entry.amountMl,
    };
  }

  HydrationEntry _hydrationFromMap(Map<String, dynamic> json) {
    return HydrationEntry(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: _asDate(json['date']) ?? DateTime.now(),
      amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _feedbackToMap(FeedbackEntry entry) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'userName': entry.userName,
      'message': entry.message,
      'createdAt': entry.createdAt,
      'rating': entry.rating,
    };
  }

  FeedbackEntry _feedbackFromMap(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      rating: (json['rating'] as num?)?.toInt(),
    );
  }

  DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _stringOrNull(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _intFrom(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  dynamic _firstNonNull(List<dynamic> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }

  double? _doubleFrom(dynamic raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  String _portionLabel(double quantity, String unit) {
    final trimmedUnit = unit.trim();
    final unitLabel = trimmedUnit;
    if (quantity == quantity.roundToDouble()) {
      return unitLabel.isEmpty
          ? '${quantity.toInt()}'
          : '${quantity.toInt()} $unitLabel';
    }
    return unitLabel.isEmpty
        ? quantity.toStringAsFixed(2)
        : '${quantity.toStringAsFixed(2)} $unitLabel';
  }

  double? _quantityFromPortion(String? portion) {
    if (portion == null) return null;
    final match = RegExp(r'^\s*(\d+(?:\.\d+)?)').firstMatch(portion);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  String? _unitFromPortion(String? portion) {
    if (portion == null) return null;
    final match = RegExp(r'^\s*\d+(?:\.\d+)?\s*(.*)$').firstMatch(portion);
    if (match == null) return null;
    final unit = match.group(1)!.trim();
    return unit.isEmpty ? null : unit;
  }

  String? _userIdFromEntryRef(
    DocumentReference<Map<String, dynamic>> ref,
  ) {
    final segments = ref.path.split('/');
    final index = segments.indexOf(FS.foodLogs);
    if (index == -1 || index + 1 >= segments.length) return null;
    return segments[index + 1];
  }

  String? _dayIdFromEntryRef(
    DocumentReference<Map<String, dynamic>> ref,
  ) {
    final segments = ref.path.split('/');
    final index = segments.indexOf('Days');
    if (index == -1 || index + 1 >= segments.length) return null;
    return segments[index + 1];
  }

  String _mealTypeFromDate(DateTime date) {
    final hour = date.hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 20) return 'dinner';
    return 'snack';
  }
}
