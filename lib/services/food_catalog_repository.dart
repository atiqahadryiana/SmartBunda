import 'dart:async';

import 'package:smartbunda/models/food_catalog_entry.dart';
import 'package:smartbunda/models/food_item.dart';
import 'package:smartbunda/services/food_database.dart';

class FoodCatalogRepository {
  FoodCatalogRepository(this._database) {
    _catalogController = StreamController<List<FoodCatalogEntry>>.broadcast(
      onListen: _emitCatalog,
    );
  }

  final FoodDatabase _database;
  List<FoodCatalogEntry>? _systemEntries;
  final Map<String, FoodCatalogEntry> _customEntries = {};
  bool _loaded = false;
  late final StreamController<List<FoodCatalogEntry>> _catalogController;

  Stream<List<FoodCatalogEntry>> watchCatalog() => _catalogController.stream;

  Future<List<FoodItem>> loadFoods() async {
    await _ensureBase();
    final system = _systemEntries!
        .where((entry) => entry.isActive)
        .map((entry) => entry.item)
        .toList();
    final custom = _customEntries.values
        .where((entry) => entry.isActive)
        .map((entry) => entry.item)
        .toList();
    return [...system, ...custom];
  }

  Future<List<FoodItem>> search(String query) async {
    final all = await loadFoods();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((item) => item.name.toLowerCase().contains(q)).toList();
  }

  Future<void> addCustomItem(FoodItem item) async {
    await _database.addFoodItem(item, isActive: true);
    _customEntries[item.id] = FoodCatalogEntry(
      item: item,
      isActive: true,
      source: FoodCatalogSource.custom,
    );
    _emitCatalog();
  }

  Future<void> addCustomItems(List<FoodItem> items) async {
    if (items.isEmpty) return;
    for (final item in items) {
      await _database.addFoodItem(item, isActive: true);
      _customEntries[item.id] = FoodCatalogEntry(
        item: item,
        isActive: true,
        source: FoodCatalogSource.custom,
      );
    }
    _emitCatalog();
  }

  Future<void> updateCustomItem(FoodItem item) async {
    final existing = _customEntries[item.id];
    await _database.updateFoodItem(item, isActive: existing?.isActive);
    _customEntries[item.id] = (existing ??
            FoodCatalogEntry(
              item: item,
              isActive: true,
              source: FoodCatalogSource.custom,
            ))
        .copyWith(item: item);
    _emitCatalog();
  }

  Future<void> removeCustomItem(String id) async {
    await _database.deleteFoodItem(id);
    _customEntries.remove(id);
    _emitCatalog();
  }

  Future<void> setItemActive(String id, bool isActive) async {
    if (_customEntries.containsKey(id)) {
      final entry = _customEntries[id]!;
      _customEntries[id] = entry.copyWith(isActive: isActive);
      await _database.setFoodItemActive(id, isActive);
    } else {
      final entry = _systemEntries?.firstWhere(
        (candidate) => candidate.item.id == id,
        orElse: () => FoodCatalogEntry(
          item: _database.getById(id) ??
              FoodItem(
                id: id,
                name: 'Unknown',
                servingSize: '',
                caloriesPerServing: 0,
                proteinG: 0,
                carbG: 0,
                fatG: 0,
                ironMg: 0,
                folateMcg: 0,
              ),
          isActive: isActive,
          source: FoodCatalogSource.system,
        ),
      );
      if (entry != null) {
        final index = _systemEntries?.indexWhere((e) => e.item.id == id) ?? -1;
        if (index >= 0) {
          _systemEntries![index] = entry.copyWith(isActive: isActive);
        }
      }
      await _database.setFoodItemActive(id, isActive);
    }
    _emitCatalog();
  }

  Map<String, dynamic> exportState() {
    return {
      'customEntries':
          _customEntries.values.map((entry) => entry.toJson()).toList(),
    };
  }

  void restoreState(Map<String, dynamic> data) {
    final rawCustom = data['customEntries'];
    if (rawCustom is List) {
      _customEntries
        ..clear()
        ..addEntries(
          rawCustom
              .whereType<Map>()
              .map((e) => FoodCatalogEntry.fromJson(e.cast<String, dynamic>()))
              .map((entry) => MapEntry(entry.item.id, entry)),
        );
    }
    _emitCatalog();
  }

  Future<void> _ensureBase() async {
    if (_loaded) return;
    _systemEntries = await _database.loadSystemEntries();
    final customEntries = await _database.loadCustomEntries();
    _customEntries
      ..clear()
      ..addEntries(
        customEntries.map((entry) => MapEntry(entry.item.id, entry)),
      );
    _loaded = true;
  }

  Future<void> refresh() async {
    _loaded = false;
    _systemEntries = null;
    _customEntries.clear();
    await _emitCatalog();
  }

  Future<void> _emitCatalog() async {
    await _ensureBase();
    final items = <FoodCatalogEntry>[
      ...?_systemEntries,
      ..._customEntries.values,
    ];
    _catalogController.add(items);
  }

  void dispose() {
    _catalogController.close();
  }
}
