import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/recommendation_audit.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/screens/food/ai_food_recommendation_card.dart';
import 'package:smartbunda/services/food_recommendation_engine.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';

/// Save workflow for an accepted AI recommendation:
/// 1. show nutrition, 2. adjust serving, 3. save meal (→ Medical Records) +
/// audit record, 4. success message.
class RecommendationConfirmScreen extends ConsumerStatefulWidget {
  const RecommendationConfirmScreen({super.key, required this.rec});

  final FoodRecommendation rec;

  @override
  ConsumerState<RecommendationConfirmScreen> createState() =>
      _RecommendationConfirmScreenState();
}

class _RecommendationConfirmScreenState
    extends ConsumerState<RecommendationConfirmScreen> {
  late double _servingG = widget.rec.servingG;
  String _mealType = 'Lunch';
  bool _saving = false;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  FoodRecommendation get _rec => widget.rec;

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _toast('Please sign in to save this meal.');
      return;
    }
    setState(() => _saving = true);
    try {
      final entry = buildEntryFromRecommendation(
        _rec,
        userId: user.id,
        servingG: _servingG,
        mealType: _mealType,
      );
      // 1. Save the meal — appears in History › Medical Records › Meal Logs.
      await ref.read(dataStoreProvider).addEntry(entry);

      // 2. Write the audit trail (guideline version, signals, reason, serving).
      final scaled = _rec.food.scaleToPortionG(_servingG);
      final now = DateTime.now();
      await ref.read(recommendationAuditRepositoryProvider).record(
            RecommendationAudit(
              id: 'audit_${now.microsecondsSinceEpoch}',
              patientId: user.id,
              foodName: _rec.food.name,
              guidelineVersion: _rec.guideline.version,
              guidelineSource: _rec.guideline.source,
              reason: _rec.reason,
              signalsUsed: _rec.signalsUsed,
              recommendedServingG: _rec.servingG,
              savedServingG: _servingG,
              calories: scaled.energyKcal,
              proteinG: scaled.proteinG,
              ironMg: scaled.ironMg,
              createdAt: now,
            ),
          );

      if (!mounted) return;
      _toast('Meal saved successfully.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast('Could not save meal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scaled = _rec.food.scaleToPortionG(_servingG);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Log This Meal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.xl),
        children: [
          SbCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: AppRadius.brM,
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.s + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_rec.food.name, style: text.titleMedium),
                      Text('${scaled.energyKcal} kcal · ${_servingG.round()} g',
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // ── Serving adjustment ─────────────────────────────────────────
          Text('Serving size', style: text.titleSmall),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _servingG.clamp(50, 600),
                  min: 50,
                  max: 600,
                  divisions: 55,
                  label: '${_servingG.round()} g',
                  onChanged: (v) => setState(() => _servingG = v),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text('${_servingG.round()} g',
                    textAlign: TextAlign.end, style: text.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // ── Meal type ──────────────────────────────────────────────────
          Text('Meal type', style: text.titleSmall),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            children: [
              for (final type in _mealTypes)
                ChoiceChip(
                  label: Text(type),
                  selected: _mealType == type,
                  onSelected: (_) => setState(() => _mealType = type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // ── Nutrition (recomputed for the chosen serving) ──────────────
          Text('Nutrition for this serving', style: text.titleSmall),
          const SizedBox(height: AppSpacing.s),
          SbCard(
            child: Column(
              children: [
                _row('Calories', '${scaled.energyKcal} kcal'),
                _row('Protein', '${scaled.proteinG} g'),
                _row('Carbohydrates', '${scaled.carbsG} g'),
                _row('Fat', '${scaled.fatG} g'),
                _row('Fiber', '${scaled.fibreG.toStringAsFixed(1)} g'),
                _row('Iron', '${scaled.ironMg.toStringAsFixed(1)} mg'),
                _row('Calcium', '${scaled.calciumMg.round()} mg'),
                _row('Sodium', '${scaled.sodiumMg.round()} mg'),
                if (scaled.sugarG != null)
                  _row('Sugar', '${scaled.sugarG!.toStringAsFixed(1)} g',
                      last: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          SbLoadingButton(
            label: 'Save Meal',
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(value,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
