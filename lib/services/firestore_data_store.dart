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
    return _firestore.collection(FS.patientProfiles).doc(userId).snapshots().map(
          (doc) => doc.exists ? _profileFromMap(doc.data()!, userId: doc.id) : null,
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
    return _firestore.collection(FS.patientProfiles).snapshots().map((snapshot) {
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
    final controller = StreamController<Pregnancy?>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    controller.onListen = () {
      sub = _firestore
          .collection(FS.pregnancies)
          .where('patientId', isEqualTo: patientId)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          controller.add(null);
          return;
        }
        controller.add(_pregnancyFromMap(snapshot.docs.first.data()));
      });
    };
    controller.onCancel = () async {
      await sub?.cancel();
    };
    return controller.stream;
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
      final map = <String, Pregnancy>{};
      for (final doc in snapshot.docs) {
        final pregnancy = _pregnancyFromMap(doc.data());
        map[pregnancy.patientId] = pregnancy;
      }
      return map;
    });
  }

  @override
  Stream<List<FoodEntry>> watchEntries(String userId) {
    final controller = StreamController<List<FoodEntry>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? logsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? itemsSub;
    Map<String, DateTime> logDates = {};
    List<Map<String, dynamic>> items = [];

    void emit() {
      final entries = items.map((item) {
        final logId = item['logId'] as String? ?? '';
        final logDate = logDates[logId];
        return _entryFromMap(item, logDate: logDate);
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      controller.add(entries);
    }

    controller.onListen = () {
      logsSub = _firestore
          .collection(FS.foodLogs)
          .where('patientId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        logDates = {
          for (final doc in snapshot.docs)
            doc.id: _parseDate(doc.data()['logDate']) ?? DateTime.now(),
        };
        emit();
      });
      itemsSub = _firestore
          .collection(FS.foodLogItems)
          .where('patientId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        items = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        emit();
      });
    };

    controller.onCancel = () async {
      await logsSub?.cancel();
      await itemsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> addEntry(FoodEntry entry) async {
    final date = entry.date;
    final logDate = _formatDate(date);
    var logId = entry.logId;
    if (logId.isEmpty) {
      final existing = await _firestore
          .collection(FS.foodLogs)
          .where('patientId', isEqualTo: entry.userId)
          .where('logDate', isEqualTo: logDate)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        logId = existing.docs.first.id;
      } else {
        logId = DateTime.now().microsecondsSinceEpoch.toString();
      }
    }

    final updated = entry.copyWith(logId: logId);
    final logRef = _firestore.collection(FS.foodLogs).doc(logId);
    final itemRef = _firestore.collection(FS.foodLogItems).doc(updated.id);
    final batch = _firestore.batch();
    batch.set(
      logRef,
      {
        'patientId': updated.userId,
        'logDate': logDate,
        'totalCalories': FieldValue.increment(updated.calories),
        'totalNutrients.protein_g': FieldValue.increment(updated.protein),
        'totalNutrients.iron_mg': FieldValue.increment(updated.ironMg),
        'totalNutrients.folate_mcg': FieldValue.increment(updated.folateMcg),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(itemRef, _entryToMap(updated));
    await batch.commit();
  }

  @override
  Stream<Map<String, List<FoodEntry>>> watchAllEntries() {
    final controller = StreamController<Map<String, List<FoodEntry>>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? logsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? itemsSub;
    Map<String, DateTime> logDates = {};
    List<Map<String, dynamic>> items = [];

    void emit() {
      final byUser = <String, List<FoodEntry>>{};
      for (final item in items) {
        final userId = item['patientId'] as String? ?? item['userId'] as String? ?? '';
        if (userId.isEmpty) continue;
        final logId = item['logId'] as String? ?? '';
        final logDate = logDates[logId];
        final entry = _entryFromMap(item, logDate: logDate);
        byUser.putIfAbsent(userId, () => []).add(entry);
      }
      for (final entries in byUser.values) {
        entries.sort((a, b) => b.date.compareTo(a.date));
      }
      controller.add(byUser);
    }

    controller.onListen = () {
      logsSub = _firestore.collection(FS.foodLogs).snapshots().listen((snapshot) {
        logDates = {
          for (final doc in snapshot.docs)
            doc.id: _parseDate(doc.data()['logDate']) ?? DateTime.now(),
        };
        emit();
      });
      itemsSub = _firestore.collection(FS.foodLogItems).snapshots().listen((snapshot) {
        items = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        emit();
      });
    };

    controller.onCancel = () async {
      await logsSub?.cancel();
      await itemsSub?.cancel();
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
          (snapshot) =>
              snapshot.docs.map((doc) => _hydrationFromMap(doc.data())).toList(),
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
      'medicalConditions': profile.medicalConditions.map(_conditionToString).toList(),
    };
  }

  Profile _profileFromMap(Map<String, dynamic> json, {String? userId}) {
    return Profile(
      patientId: json['patientId'] as String? ?? userId ?? '',
      dob: json['dob'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
      bloodType: json['bloodType'] as String? ?? '',
      medicalConditions: _conditionsFromJson(json['medicalConditions']),
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

  Pregnancy _pregnancyFromMap(Map<String, dynamic> json) {
    return Pregnancy(
      id: json['pregnancyId'] as String? ?? json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      gestationalWeek: (json['gestationalWeek'] as num?)?.toInt() ?? 0,
      trimester: (json['trimester'] as num?)?.toInt() ?? 0,
      edd: json['edd'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '',
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> _entryToMap(FoodEntry entry) {
    return {
      'patientId': entry.userId,
      'logId': entry.logId,
      'foodId': entry.foodId,
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
    };
  }

  FoodEntry _entryFromMap(Map<String, dynamic> json, {DateTime? logDate}) {
    final nutrients = (json['nutrients'] as Map?)?.cast<String, dynamic>() ?? {};
    return FoodEntry(
      id: json['id'] as String? ?? '',
      userId: json['patientId'] as String? ?? json['userId'] as String? ?? '',
      logId: json['logId'] as String? ?? '',
      foodId: json['foodId'] as String? ?? '',
      date: logDate ?? DateTime.now(),
      meal: json['foodName'] as String? ?? (json['foodId'] as String? ?? 'Meal'),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'serving',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (nutrients['protein_g'] as num?)?.toInt() ?? 0,
      carbs: (nutrients['carb_g'] as num?)?.toInt() ?? 0,
      fat: (nutrients['fat_g'] as num?)?.toInt() ?? 0,
      ironMg: (nutrients['iron_mg'] as num?)?.toDouble() ?? 0,
      folateMcg: (nutrients['folate_mcg'] as num?)?.toDouble() ?? 0,
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
}
