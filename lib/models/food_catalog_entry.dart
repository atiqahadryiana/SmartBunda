import 'package:smartbunda/models/food_item.dart';

enum FoodCatalogSource { system, custom }

class FoodCatalogEntry {
  FoodCatalogEntry({
    required this.item,
    required this.isActive,
    required this.source,
  });

  final FoodItem item;
  final bool isActive;
  final FoodCatalogSource source;

  FoodCatalogEntry copyWith({
    FoodItem? item,
    bool? isActive,
    FoodCatalogSource? source,
  }) {
    return FoodCatalogEntry(
      item: item ?? this.item,
      isActive: isActive ?? this.isActive,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': {
        'id': item.id,
        'name': item.name,
        'servingSize': item.servingSize,
        'caloriesPerServing': item.caloriesPerServing,
        'nutrients': {
          'protein_g': item.proteinG,
          'carb_g': item.carbG,
          'fat_g': item.fatG,
          'iron_mg': item.ironMg,
          'folate_mcg': item.folateMcg,
          'calcium_mg': item.calciumMg,
          'vitamin_d_mcg': item.vitaminDMcg,
          'vitamin_b12_mcg': item.vitaminB12Mcg,
          'sodium_mg': item.sodiumMg,
        },
      },
      'isActive': isActive,
      'source': source.name,
    };
  }

  factory FoodCatalogEntry.fromJson(Map<String, dynamic> json) {
    final itemJson = (json['item'] as Map).cast<String, dynamic>();
    return FoodCatalogEntry(
      item: FoodItem(
        id: itemJson['id'] as String,
        name: itemJson['name'] as String,
        servingSize: itemJson['servingSize'] as String? ?? '',
        caloriesPerServing: (itemJson['caloriesPerServing'] as num?)?.toInt() ?? 0,
        proteinG: _numToInt(_readNutrient(itemJson, 'protein_g')),
        carbG: _numToInt(_readNutrient(itemJson, 'carb_g')),
        fatG: _numToInt(_readNutrient(itemJson, 'fat_g')),
        ironMg: _numToDouble(_readNutrient(itemJson, 'iron_mg')),
        folateMcg: _numToDouble(_readNutrient(itemJson, 'folate_mcg')),
        calciumMg: _numToDouble(_readNutrient(itemJson, 'calcium_mg')),
        vitaminDMcg: _numToDouble(_readNutrient(itemJson, 'vitamin_d_mcg')),
        vitaminB12Mcg: _numToDouble(_readNutrient(itemJson, 'vitamin_b12_mcg')),
        sodiumMg: _numToDouble(_readNutrient(itemJson, 'sodium_mg')),
      ),
      isActive: json['isActive'] as bool? ?? true,
      source: _sourceFromString(json['source'] as String?),
    );
  }

  static dynamic _readNutrient(Map<String, dynamic> itemJson, String key) {
    final nutrients = itemJson['nutrients'];
    if (nutrients is Map) {
      return nutrients[key];
    }
    return itemJson[key];
  }

  static int _numToInt(dynamic value) =>
      value == null ? 0 : (value as num).toInt();

  static double _numToDouble(dynamic value) =>
      value == null ? 0 : (value as num).toDouble();

  static FoodCatalogSource _sourceFromString(String? value) {
    switch (value) {
      case 'custom':
        return FoodCatalogSource.custom;
      case 'system':
      default:
        return FoodCatalogSource.system;
    }
  }
}
