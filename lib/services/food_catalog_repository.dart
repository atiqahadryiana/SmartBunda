import 'dart:async';

import '../models/food_catalog_entry.dart';
import '../models/food_item.dart';
import 'food_database.dart';

class FoodCatalogRepository {
  FoodCatalogRepository(this._database) {
    _catalogController = StreamController<List<FoodCatalogEntry>>.broadcast(
      onListen: _emitCatalog,
    );
  }

  final FoodDatabase _database;
  List<FoodItem>? _baseFoods;
  final Map<String, FoodCatalogEntry> _customEntries = {};
  final Set<String> _disabledSystemIds = {};
  late final StreamController<List<FoodCatalogEntry>> _catalogController;

  Stream<List<FoodCatalogEntry>> watchCatalog() => _catalogController.stream;

  Future<List<FoodItem>> loadFoods() async {
    await _ensureBase();
    final system = _baseFoods!
        .where((item) => !_disabledSystemIds.contains(item.id))
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
    _customEntries[item.id] = FoodCatalogEntry(
      item: item,
      isActive: true,
      source: FoodCatalogSource.custom,
    );
    _emitCatalog();
  }

  Future<void> updateCustomItem(FoodItem item) async {
    final existing = _customEntries[item.id];
    if (existing == null) return;
    _customEntries[item.id] = existing.copyWith(item: item);
    _emitCatalog();
  }

  Future<void> removeCustomItem(String id) async {
    _customEntries.remove(id);
    _emitCatalog();
  }

  Future<void> setItemActive(String id, bool isActive) async {
    if (_customEntries.containsKey(id)) {
      final entry = _customEntries[id]!;
      _customEntries[id] = entry.copyWith(isActive: isActive);
    } else {
      if (isActive) {
        _disabledSystemIds.remove(id);
      } else {
        _disabledSystemIds.add(id);
      }
    }
    _emitCatalog();
  }

  Map<String, dynamic> exportState() {
    return {
      'customEntries':
          _customEntries.values.map((entry) => entry.toJson()).toList(),
      'disabledSystemIds': _disabledSystemIds.toList(),
    };
  }

  void restoreState(Map<String, dynamic> data) {
    final rawCustom = data['customEntries'];
    final rawDisabled = data['disabledSystemIds'];
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
    if (rawDisabled is List) {
      _disabledSystemIds
        ..clear()
        ..addAll(rawDisabled.whereType<String>());
    }
    _emitCatalog();
  }

  Future<void> _ensureBase() async {
    _baseFoods ??= await _database.loadFoods();
  }

  void _emitCatalog() async {
    await _ensureBase();
    final items = <FoodCatalogEntry>[
      ..._baseFoods!.map(
        (item) => FoodCatalogEntry(
          item: item,
          isActive: !_disabledSystemIds.contains(item.id),
          source: FoodCatalogSource.system,
        ),
      ),
      ..._customEntries.values,
    ];
    _catalogController.add(items);
  }

  void dispose() {
    _catalogController.close();
  }
}
