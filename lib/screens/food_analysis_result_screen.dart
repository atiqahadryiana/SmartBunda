/// SmartBunda — Food Analysis Result Screen
///
/// Shown after the camera / gallery image is classified by the TFLite model.
/// Displays:
///   • Detected food image
///   • AI predictions with confidence bars
///   • MyFCD nutrition facts (from local offline database)
///   • Portion size slider
///   • Meal type selector
///   • "Save Food Log" button
library smartbunda.food_analysis_result_screen;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_entry.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../services/food_image_classifier_api.dart';
import '../theme/app_theme.dart';
import '../utils/food_nutrition_lookup.dart';

// ── Meal type enum ────────────────────────────────────────────────────────────

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch:     return 'Lunch';
      case MealType.dinner:    return 'Dinner';
      case MealType.snack:     return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast: return Icons.wb_sunny_outlined;
      case MealType.lunch:     return Icons.wb_cloudy_outlined;
      case MealType.dinner:    return Icons.nights_stay_outlined;
      case MealType.snack:     return Icons.cookie_outlined;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FoodAnalysisResultScreen extends ConsumerStatefulWidget {
  const FoodAnalysisResultScreen({
    super.key,
    required this.imageBytes,
    required this.predictions,
  });

  final Uint8List imageBytes;
  final List<FoodImagePrediction> predictions;

  @override
  ConsumerState<FoodAnalysisResultScreen> createState() =>
      _FoodAnalysisResultScreenState();
}

class _FoodAnalysisResultScreenState
    extends ConsumerState<FoodAnalysisResultScreen> {
  late int _selectedPredictionIndex;
  MealType _mealType = _defaultMealType();
  double _portionG = 200.0;
  bool _saving = false;
  bool _saved = false;

  static MealType _defaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void initState() {
    super.initState();
    _selectedPredictionIndex = 0;
    // Initialise portion to the default for the matched food entry
    final entry = _nutritionForSelected;
    if (entry != null) _portionG = entry.defaultPortionG;
  }

  FoodNutritionData? get _nutritionForSelected {
    if (widget.predictions.isEmpty) return null;
    final label = widget.predictions[_selectedPredictionIndex].label;
    return LocalNutritionLookup.lookup(label);
  }

  FoodNutritionData? get _nutritionScaled {
    return _nutritionForSelected?.scaleToPortionG(_portionG);
  }

  Future<void> _saveLog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final nutrition = _nutritionScaled;
    final prediction = widget.predictions[_selectedPredictionIndex];
    setState(() => _saving = true);

    try {
      final ts = DateTime.now().microsecondsSinceEpoch.toString();
      final entry = FoodEntry(
        id:       ts,
        userId:   user.id,
        logId:    '${ts}_log',
        foodId:   prediction.label,
        date:     DateTime.now(),
        meal:     prediction.displayName,
        quantity: _portionG,
        unit:     'g',
        calories: nutrition?.energyKcal ?? 0,
        protein:  nutrition?.proteinG   ?? 0,
        carbs:    nutrition?.carbsG      ?? 0,
        fat:      nutrition?.fatG        ?? 0,
        ironMg:   nutrition?.ironMg      ?? 0,
        mealType: _mealType.label,
        notes:    'AI scan (${prediction.confidenceLabel})',
      );
      await ref.read(dataStoreProvider).addEntry(entry);
      ref.invalidate(entriesProvider);
      if (mounted) setState(() => _saved = true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = _nutritionScaled;
    final top = widget.predictions.isNotEmpty
        ? widget.predictions[_selectedPredictionIndex]
        : null;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        elevation: 0,
        title: const Text(
          'Food Analysis',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Image hero ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _ImageHero(bytes: widget.imageBytes, topPred: top)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList.list(
              children: [
                // ── Confidence predictions ───────────────────────────────
                const _SectionTitle(icon: Icons.auto_awesome_outlined,
                    title: 'Detected Foods', color: AppTheme.darkPink),
                const SizedBox(height: 10),
                _PredictionList(
                  predictions: widget.predictions,
                  selectedIndex: _selectedPredictionIndex,
                  onSelect: (idx) {
                    setState(() {
                      _selectedPredictionIndex = idx;
                      final e = _nutritionForSelected;
                      if (e != null) _portionG = e.defaultPortionG;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // ── Portion selector ─────────────────────────────────────
                const _SectionTitle(icon: Icons.straighten_outlined,
                    title: 'Portion Size', color: AppTheme.healthcareTeal),
                const SizedBox(height: 8),
                _PortionSlider(
                  value: _portionG,
                  onChanged: (v) => setState(() => _portionG = v),
                ),
                const SizedBox(height: 18),

                // ── Meal type ────────────────────────────────────────────
                const _SectionTitle(icon: Icons.restaurant_outlined,
                    title: 'Meal Type', color: AppTheme.info),
                const SizedBox(height: 10),
                _MealTypeSelector(
                  selected: _mealType,
                  onSelect: (t) => setState(() => _mealType = t),
                ),
                const SizedBox(height: 18),

                // ── Nutrition facts ──────────────────────────────────────
                const _SectionTitle(icon: Icons.pie_chart_outline,
                    title: 'Nutrition Facts (MyFCD)',
                    color: AppTheme.darkPink),
                const SizedBox(height: 10),
                if (nutrition != null)
                  _NutritionFactsCard(nutrition: nutrition, portionG: _portionG)
                else
                  const _NoNutritionCard(),

                // ── Disclaimer ───────────────────────────────────────────
                const SizedBox(height: 14),
                const _DisclaimerBanner(),
              ],
            ),
          ),
        ],
      ),

      // ── Save FAB ──────────────────────────────────────────────────────────
      bottomNavigationBar: _SaveBar(
        saving: _saving,
        saved: _saved,
        onSave: _saveLog,
        onRescan: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

// ── Image hero ────────────────────────────────────────────────────────────────

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.bytes, required this.topPred});

  final Uint8List bytes;
  final FoodImagePrediction? topPred;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 240,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
        // Dark scrim at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent,
                  Colors.black.withValues(alpha: 160)],
              ),
            ),
          ),
        ),
        // Food name overlay
        if (topPred != null)
          Positioned(
            bottom: 14, left: 16, right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    topPred!.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ConfidenceBadge(confidence: topPred!.confidence),
              ],
            ),
          ),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  Color get _color {
    if (confidence >= 0.7) return AppTheme.success;
    if (confidence >= 0.4) return AppTheme.warning;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 220),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

// ── Prediction list ───────────────────────────────────────────────────────────

class _PredictionList extends StatelessWidget {
  const _PredictionList({
    required this.predictions,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<FoodImagePrediction> predictions;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < predictions.length; i++) ...[
            _PredictionRow(
              prediction: predictions[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
            if (i < predictions.length - 1)
              const Divider(height: 16, color: Color(0xFFF8BBD0)),
          ],
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    required this.prediction,
    required this.selected,
    required this.onTap,
  });

  final FoodImagePrediction prediction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.darkPink : AppTheme.secondaryText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: color, size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.displayName,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppTheme.primaryText : AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Confidence bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: prediction.confidence,
                      backgroundColor: const Color(0xFFF8BBD0),
                      color: selected ? AppTheme.darkPink : const Color(0xFFF48FB1),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              prediction.confidenceLabel,
              style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portion slider ────────────────────────────────────────────────────────────

class _PortionSlider extends StatelessWidget {
  const _PortionSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Portion', style: TextStyle(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)} g',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.darkPink,
              thumbColor: AppTheme.darkPink,
              inactiveTrackColor: const Color(0xFFF8BBD0),
              overlayColor: AppTheme.primaryPink.withValues(alpha: 30),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(10.0, 1000.0),
              min: 10, max: 1000, divisions: 99,
              onChanged: onChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10 g', style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
              Text('1000 g', style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meal type selector ────────────────────────────────────────────────────────

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.selected, required this.onSelect});

  final MealType selected;
  final ValueChanged<MealType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.darkPink
                        : const Color(0xFFF8BBD0),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.darkPink.withValues(alpha: 50),
                      blurRadius: 10, offset: const Offset(0, 4)),
                  ] : null,
                ),
                child: Column(
                  children: [
                    Icon(type.icon, size: 20,
                        color: isSelected ? Colors.white : AppTheme.secondaryText),
                    const SizedBox(height: 4),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Nutrition facts card ──────────────────────────────────────────────────────

class _NutritionFactsCard extends StatelessWidget {
  const _NutritionFactsCard({required this.nutrition, required this.portionG});

  final FoodNutritionData nutrition;
  final double portionG;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nutrition.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'per ${portionG.toStringAsFixed(0)} g · MyFCD',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${nutrition.energyKcal}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900, color: AppTheme.darkPink),
                    ),
                    const Text('kcal',
                        style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Macro row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _MacroTile(label: 'Protein',
                    value: '${nutrition.proteinG} g', color: AppTheme.healthcareTeal),
                _MacroTile(label: 'Carbs',
                    value: '${nutrition.carbsG} g', color: AppTheme.info),
                _MacroTile(label: 'Fat',
                    value: '${nutrition.fatG} g', color: AppTheme.darkPink),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF8BBD0)),
          // Micronutrients
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _MicroRow('Dietary Fibre',
                    '${nutrition.fibreG.toStringAsFixed(1)} g'),
                _MicroRow('Sodium',
                    '${nutrition.sodiumMg.toStringAsFixed(0)} mg'),
                _MicroRow('Calcium',
                    '${nutrition.calciumMg.toStringAsFixed(0)} mg'),
                _MicroRow('Iron',
                    '${nutrition.ironMg.toStringAsFixed(1)} mg', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MicroRow extends StatelessWidget {
  const _MicroRow(this.label, this.value, {this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF8BBD0)),
      ],
    );
  }
}

class _NoNutritionCard extends StatelessWidget {
  const _NoNutritionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nutritional data not available in local MyFCD database '
              'for this food. Log manually to add nutrition details.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nutritional values are estimates based on the Malaysian Food '
              'Composition Database (MyFCD) and may vary by preparation method '
              'and ingredients.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6D4C00), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.saved,
    required this.onSave,
    required this.onRescan,
  });

  final bool saving;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // Rescan button
            OutlinedButton.icon(
              onPressed: saving ? null : onRescan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Rescan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.darkPink,
                side: const BorderSide(color: Color(0xFFF8BBD0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(width: 12),
            // Save button
            Expanded(
              child: GradientButton(
                onPressed: (saving || saved) ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            saved ? Icons.check_circle : Icons.save_outlined,
                            color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            saved ? 'Saved!' : 'Save Food Log',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
