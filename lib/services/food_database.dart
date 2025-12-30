import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../models/food_item.dart';

class FoodDatabase {
  FoodDatabase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  List<FoodItem>? _cache;

  Future<List<FoodItem>> loadFoods() async {
    if (_cache != null) return _cache!;
    final snapshot = await _firestore.collection(FS.foods).orderBy('name').get();
    _cache = snapshot.docs
        .map((doc) => FoodItem.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    return _cache!;
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
}
