/// SmartBunda — Food Picker Confirm Screen
///
/// Confirmation screen after selecting a food from the local database.
/// Allows user to adjust portion size and meal type before saving to food log.
library smartbunda.food_picker_confirm_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_entry.dart';
import '../providers/app_providers.dart';
import '../screens/food_picker_modal.dart';
import '../services/service_providers.dart';
import '../theme/app_theme.dart';

// ── Meal Type ────────────────────────────────────────────────────────────────

enum _MealType {
  breakfast(Icons.wb_sunny_outlined),
  lunch(Icons.light_mode_outlined),
  dinner(Icons.dark_mode_outlined),
  snack(Icons.emoji_food_beverage_outlined);

  const _MealType(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case _MealType.breakfast:
        return 'breakfast';
      case _MealType.lunch:
        return 'lunch';
      case _MealType.dinner:
        return 'dinner';
      case _MealType.snack:
        return 'snack';
    }
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class FoodPickerConfirmScreen extends ConsumerStatefulWidget {
  const FoodPickerConfirmScreen({
    super.key,
    required this.result,
  });

  final FoodPickerResult result;

  @override
  ConsumerState<FoodPickerConfirmScreen> createState() =>
      _FoodPickerConfirmScreenState();
}

class _FoodPickerConfirmScreenState
    extends ConsumerState<FoodPickerConfirmScreen> {
  late double _portionG;
  late _MealType _mealType;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _portionG = widget.result.quantity;
    _mealType = _inferMealType();
  }

  _MealType _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return _MealType.breakfast;
    if (hour >= 12 && hour < 17) return _MealType.lunch;
    if (hour >= 17 && hour < 22) return _MealType.dinner;
    return _MealType.snack;
  }

  Future<void> _saveLog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final nutrition = widget.result.food.scaleToPortionG(_portionG);
      final id = DateTime.now().microsecondsSinceEpoch.toString();

      final entry = FoodEntry(
        id: id,
        userId: user.id,
        logId: '${id}_log',
        foodId:
            widget.result.food.name.toLowerCase().replaceAll(' ', '_'),
        date: DateTime.now(),
        meal: widget.result.food.name,
        quantity: _portionG,
        unit: 'g',
        calories: nutrition.energyKcal,
        protein: nutrition.proteinG.round(),
        carbs: nutrition.carbsG.round(),
        fat: nutrition.fatG.round(),
        ironMg: nutrition.ironMg,
        folateMcg: 0,
        mealType: _mealType.label,
        notes: 'Manual selection (MyFCD)',
      );

      await ref.read(dataStoreProvider).addEntry(entry);
      ref.invalidate(entriesProvider);

      setState(() => _saved = true);
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.result.food.scaleToPortionG(_portionG);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Food'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Food Info Card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF8BBD0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.food.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.result.food.category[0].toUpperCase() +
                      widget.result.food.category.substring(1),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${nutrition.energyKcal}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            nutrition.proteinG.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'g protein',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            nutrition.carbsG.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'g carbs',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Portion Slider ──────────────────────────────────────────────
          Text(
            'Portion Size',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _portionG,
            min: 10,
            max: 1000,
            divisions: 99,
            label: '${_portionG.toStringAsFixed(0)}g',
            onChanged: (value) {
              setState(() => _portionG = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10g',
                    style: Theme.of(context).textTheme.labelSmall),
                Text('${_portionG.toStringAsFixed(0)}g',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('1000g',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Meal Type Selector ──────────────────────────────────────────
          Text(
            'Meal Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _MealType.values.map((type) {
                final isSelected = type == _mealType;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _mealType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.darkPink
                              : const Color(0xFFF8BBD0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.darkPink.withValues(alpha: 50),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            color:
                                isSelected ? Colors.white : AppTheme.darkPink,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.name[0].toUpperCase() +
                                type.name.substring(1),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.secondaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Nutrition Facts ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8BBD0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Facts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _NutritionRow('Energy', '${nutrition.energyKcal} kcal'),
                _NutritionRow(
                    'Protein', '${nutrition.proteinG.toStringAsFixed(1)}g'),
                _NutritionRow('Carbs', '${nutrition.carbsG.toStringAsFixed(1)}g'),
                _NutritionRow('Fat', '${nutrition.fatG.toStringAsFixed(1)}g'),
                _NutritionRow(
                    'Fibre', '${nutrition.fibreG.toStringAsFixed(1)}g'),
                _NutritionRow(
                    'Iron', '${nutrition.ironMg.toStringAsFixed(2)}mg'),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ── Save Button ────────────────────────────────────────────────
          FilledButton(
            onPressed: _saving || _saved ? null : _saveLog,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.darkPink,
              disabledBackgroundColor: AppTheme.disabledText,
            ),
            child: _saving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 200),
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : _saved
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text('Saved'),
                        ],
                      )
                    : const Text('Save Food Entry'),
          ),

          const SizedBox(height: 16),

          // ── Medical Disclaimer ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0).withValues(alpha: 200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outlined,
                  color: Color(0xFFE65100),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nutritional values are estimates based on the Malaysian Food Composition Database (MyFCD) and may vary by preparation method.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFBF360C),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition Row ─────────────────────────────────────────────────────────────

class _NutritionRow extends StatelessWidget {
  const _NutritionRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkPink,
                ),
          ),
        ],
      ),
    );
  }
}
