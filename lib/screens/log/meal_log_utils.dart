import 'package:flutter/material.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/food_item.dart';
import 'package:smartbunda/widgets/portion_icon.dart';

class MealOption {
  const MealOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

List<MealOption> mealOptions(AppStrings strings) {
  return [
    MealOption(value: 'breakfast', label: strings.t('Breakfast')),
    MealOption(value: 'lunch', label: strings.t('Lunch')),
    MealOption(value: 'dinner', label: strings.t('Dinner')),
    MealOption(value: 'supper', label: strings.t('Supper')),
  ];
}

String mealTypeLabel(String? value, AppStrings strings) {
  final normalized = value?.trim().toLowerCase();
  final match = mealOptions(strings).firstWhere(
    (option) => option.value == normalized,
    orElse: () => MealOption(value: 'meal', label: strings.t('Meal')),
  );
  return match.label;
}

String defaultMealType() {
  return mealTypeFromDate(DateTime.now());
}

String mealTypeFromDate(DateTime date) {
  final hour = date.hour;
  if (hour < 11) return 'breakfast';
  if (hour < 15) return 'lunch';
  if (hour < 20) return 'dinner';
  return 'supper';
}

double? parseQuantity(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  var normalized = trimmed;
  if (normalized.contains('.') && normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }
  final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
  if (match == null) return null;
  final parsed = double.tryParse(match.group(0)!);
  if (parsed == null) return null;
  return roundTo2(parsed);
}

double parseOptionalDouble(String value) {
  return parseQuantity(value) ?? 0;
}

double roundTo2(double value) {
  return (value * 100).roundToDouble() / 100;
}

FoodEntry entryFromFood(
  String userId,
  FoodItem item, {
  required String mealType,
  double quantity = 1,
}) {
  final roundedQuantity = roundTo2(quantity);
  return FoodEntry(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    userId: userId,
    logId: '',
    foodId: item.id,
    date: DateTime.now(),
    meal: item.name,
    quantity: roundedQuantity,
    unit: item.servingSize,
    calories: (item.caloriesPerServing * roundedQuantity).round(),
    protein: (item.proteinG * roundedQuantity).round(),
    carbs: (item.carbG * roundedQuantity).round(),
    fat: (item.fatG * roundedQuantity).round(),
    ironMg: roundTo2(item.ironMg * roundedQuantity),
    folateMcg: roundTo2(item.folateMcg * roundedQuantity),
    mealType: mealType,
  );
}

/// Lets the user pick a plate portion (1/3, 1/2, 2/3, 3/4, 1 plate) for [item].
///
/// Returns the chosen fraction (0–1), which is used directly as the [quantity]
/// multiplier in [entryFromFood] — so the saved nutrition is
/// `per-serving value × fraction`, matching the per-portion nutrition formula.
/// Each row previews the resulting calories for that portion.
Future<double?> promptPlatePortion(
  BuildContext context,
  AppStrings strings,
  FoodItem item,
) {
  return showModalBottomSheet<double>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.t('How much of a plate?'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final portion in PlatePortion.values)
            ListTile(
              leading: PortionIcon(portion: portion),
              title: Text(portion.label),
              subtitle: Text(
                '${(item.caloriesPerServing * portion.fraction).round()} kcal'
                ' | P ${(item.proteinG * portion.fraction).round()}g'
                ' | C ${(item.carbG * portion.fraction).round()}g'
                ' | F ${(item.fatG * portion.fraction).round()}g',
              ),
              onTap: () => Navigator.of(context).maybePop(portion.fraction),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<String?> selectMealType(BuildContext context) async {
  final strings = AppStrings.of(context);
  final initial = defaultMealType();
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mealOptions(strings)
            .map(
              (option) => ListTile(
                title: Text(option.label),
                trailing: option.value == initial
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).maybePop(option.value),
              ),
            )
            .toList(),
      ),
    ),
  );
}
