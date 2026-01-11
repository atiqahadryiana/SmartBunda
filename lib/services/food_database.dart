import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/food_catalog_entry.dart';
import '../models/food_item.dart';

class FoodDatabase {
  FoodDatabase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  List<FoodItem>? _cache;
  List<FoodCatalogEntry>? _customCache;
  List<FoodCatalogEntry>? _systemCache;

  Future<List<FoodItem>> loadFoods() async {
    if (_cache != null) return _cache!;
    final snapshot = await _firestore.collection(FS.foods).orderBy('name').get();
    _cache = snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['source'] != 'custom' && data['isActive'] != false;
        })
        .map((doc) => FoodItem.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    return _cache!;
  }

  Future<List<FoodCatalogEntry>> loadSystemEntries() async {
    if (_systemCache != null) return _systemCache!;
    final snapshot = await _firestore.collection(FS.foods).orderBy('name').get();
    final entries = snapshot.docs
        .where((doc) => doc.data()['source'] != 'custom')
        .map((doc) {
          final data = doc.data();
          return FoodCatalogEntry(
            item: FoodItem.fromJson({'id': doc.id, ...data}),
            isActive: data['isActive'] as bool? ?? true,
            source: FoodCatalogSource.system,
          );
        })
        .toList();
    _systemCache = entries;
    return entries;
  }

  Future<List<FoodCatalogEntry>> loadCustomEntries() async {
    if (_customCache != null) return _customCache!;
    final snapshot = await _firestore
        .collection(FS.foods)
        .where('source', isEqualTo: 'custom')
        .get();
    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      return FoodCatalogEntry(
        item: FoodItem.fromJson({'id': doc.id, ...data}),
        isActive: data['isActive'] as bool? ?? true,
        source: FoodCatalogSource.custom,
      );
    }).toList()
      ..sort((a, b) => a.item.name.compareTo(b.item.name));
    _customCache = entries;
    return entries;
  }

  Future<List<FoodItem>> search(String query) async {
    final foods = await loadFoods();
    if (query.isEmpty) return foods;
    final q = query.toLowerCase();
    return foods.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  FoodItem? getById(String id) {
    final foods = _cache;
    if (foods == null) return null;
    for (final item in foods) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Adds a new food item to the Foods catalog.
  /// This operation requires admin privileges according to Firestore security rules.
  Future<void> addFoodItem(FoodItem foodItem, {bool isActive = true}) async {
    final collection = _firestore.collection(FS.foods);
    final docRef = foodItem.id.isEmpty ? collection.doc() : collection.doc(foodItem.id);
    await docRef.set(_toFoodDoc(foodItem, isActive: isActive));
    _customCache = null;
    _systemCache = null;
  }

  /// Updates an existing food item in the Foods catalog.
  /// This operation requires admin privileges according to Firestore security rules.
  Future<void> updateFoodItem(FoodItem foodItem, {bool? isActive}) async {
    if (foodItem.id.isEmpty) {
      throw ArgumentError('FoodItem must have an ID to be updated.');
    }
    await _firestore.collection(FS.foods).doc(foodItem.id).set(
      _toFoodDoc(foodItem, isActive: isActive, includeCreatedAt: false),
      SetOptions(merge: true), // Use merge to only update provided fields
    );
    _customCache = null;
    _systemCache = null;
  }

  Future<void> setFoodItemActive(String id, bool isActive) async {
    await _firestore.collection(FS.foods).doc(id).set(
      {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _customCache = null;
    _systemCache = null;
    _cache = null;
  }

  Future<void> deleteFoodItem(String id) async {
    await _firestore.collection(FS.foods).doc(id).delete();
    _customCache = null;
    _systemCache = null;
    _cache = null;
  }

  Map<String, dynamic> _toFoodDoc(
    FoodItem item, {
    required bool? isActive,
    bool includeCreatedAt = true,
  }) {
    final payload = {
      'name': item.name,
      'servingSize': item.servingSize,
      'caloriesPerServing': item.caloriesPerServing,
        'nutrients.protein_g': item.proteinG,
        'nutrients.carb_g': item.carbG,
        'nutrients.fat_g': item.fatG,
        'nutrients.iron_mg': item.ironMg,
        'nutrients.folate_mcg': item.folateMcg,
      
      'source': 'custom',
      if (isActive != null) 'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (includeCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    return payload;
  }
}
