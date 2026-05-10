import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/food_entry.dart';
import '../../models/food_item.dart';

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

Future<double?> promptQuantity(
  BuildContext context,
  AppStrings strings,
  FoodItem item,
) async {
  final controller = TextEditingController(text: '1');
  String? errorText;
  final result = await showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(strings.t('Quantity')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: strings.t('Quantity'),
            errorText: errorText,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(strings.t('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final parsed = parseQuantity(controller.text);
              if (parsed == null || parsed <= 0) {
                setState(() => errorText = strings.numberField);
                return;
              }
              Navigator.of(context).maybePop(parsed);
            },
            child: Text(strings.t('Save')),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
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
