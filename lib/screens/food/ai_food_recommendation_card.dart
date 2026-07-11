import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/food_recommendation_engine.dart';
import 'package:smartbunda/screens/food/recommendation_confirm_screen.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/utils/food_nutrition_lookup.dart';

/// "AI Food Recommendation" card shown at the top of the Log Meal hub.
///
/// Displays ONE guideline-compliant recommendation at a time with its nutrition
/// values, a Guideline Compliance section, a plain-language "Why this meal?"
/// explanation, and actions to log it, view details, or generate another.
class AiFoodRecommendationCard extends ConsumerWidget {
  const AiFoodRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(foodRecommendationProvider);
    final guideline = ref.watch(activeGuidelineProvider);
    final meals = ref.watch(todaysMealsProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // The card always sits on a fixed light blush gradient, so pin its text to
    // dark on-light tones — otherwise dark-mode (light) text vanishes here.
    const onLight = AppTheme.primaryText; // near-black
    const onLightMuted = AppTheme.secondaryText;

    final usingDefaultGuideline =
        guideline.version == 'moh-my-maternal-1.0';

    return SbCard(
      gradient: AppTheme.blushGradient,
      semanticLabel: 'AI Food Recommendation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: AppRadius.brM,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.s + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Food Recommendation',
                        style: text.titleMedium?.copyWith(color: onLight)),
                    Text(
                      'Personalized according to your health profile and '
                      'nutrition guidelines.',
                      style: text.bodySmall?.copyWith(color: onLightMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // ── Body: empty states or the recommendation ───────────────────
          if (meals.isEmpty && rec == null)
            _hint(context,
                'Complete your first meal log to receive personalized '
                'recommendations.')
          else if (rec == null)
            _hint(context,
                'No safe recommendation is available right now. Try logging a '
                'meal manually.')
          else ...[
            _RecommendationBody(rec: rec),
            const SizedBox(height: AppSpacing.s),
            if (usingDefaultGuideline)
              Text(
                'Using built-in MOH maternal nutrition guidance. '
                'No custom guideline is attached.',
                style: text.labelSmall?.copyWith(color: onLightMuted),
              )
            else
              Text('Guideline: ${guideline.source}',
                  style: text.labelSmall?.copyWith(color: onLightMuted)),
            const SizedBox(height: AppSpacing.m),
            _Actions(rec: rec),
          ],
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.45)),
        ),
      ],
    );
  }
}

class _RecommendationBody extends StatelessWidget {
  const _RecommendationBody({required this.rec});
  final FoodRecommendation rec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final f = rec.food;
    // Compact summary only — the full nutrition breakdown, compliance section
    // and "Why this meal?" live behind the "Nutrition Details" button.
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.brM,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child:
              Icon(Icons.restaurant_rounded, color: scheme.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.name,
                  style: text.titleSmall?.copyWith(color: AppTheme.primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                '${f.energyKcal} kcal · ${f.proteinG}g protein · '
                '${rec.servingG.round()}g',
                style: text.bodySmall?.copyWith(color: AppTheme.secondaryText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.food});
  final FoodNutritionData food;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Calories', '${food.energyKcal} kcal'),
      ('Protein', '${food.proteinG} g'),
      ('Carbs', '${food.carbsG} g'),
      ('Fat', '${food.fatG} g'),
      ('Fiber', '${food.fibreG.toStringAsFixed(1)} g'),
      ('Iron', '${food.ironMg.toStringAsFixed(1)} mg'),
      ('Calcium', '${food.calciumMg.round()} mg'),
      ('Sodium', '${food.sodiumMg.round()} mg'),
      if (food.sugarG != null) ('Sugar', '${food.sugarG!.toStringAsFixed(1)} g'),
    ];
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final (label, value) in items)
          _NutrientChip(label: label, value: value),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.brS,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          Text(value,
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.check});
  final ComplianceCheck check;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SmartBundaColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final color = check.passed ? semantic.success : semantic.warning;
    return Semantics(
      label:
          '${check.passed ? 'Met' : 'Not fully met'}: ${check.label}. ${check.note ?? ''}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            check.passed
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.label,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (!check.passed && check.note != null)
                  Text(check.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.rec});
  final FoodRecommendation rec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecommendationConfirmScreen(rec: rec),
              ),
            ),
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Log This Meal'),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDetails(context, rec),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Nutrition Details'),
                // Fixed colours — the card's blush gradient is always light.
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkPink,
                  side: BorderSide(
                      color: AppTheme.darkPink.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(recommendationSeedProvider.notifier)
                    .update((s) => s + 1),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkPink,
                  side: BorderSide(
                      color: AppTheme.darkPink.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, FoodRecommendation rec) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.l, 0, AppSpacing.l, AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rec.food.name,
                  style: Theme.of(ctx).textTheme.titleLarge),
              Text('Per ${rec.servingG.round()} g serving',
                  style: Theme.of(ctx).textTheme.bodySmall),
              if (rec.estimatedFromSimilar) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Estimated nutritional values based on similar foods.',
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.m),
              _NutritionGrid(food: rec.food),
              const SizedBox(height: AppSpacing.m),
              Text('Guideline Compliance',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s),
              for (final c in rec.compliance)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ComplianceRow(check: c),
                ),
              const SizedBox(height: AppSpacing.m),
              Text('Why this meal?',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(rec.reason,
                  style:
                      Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience for building a FoodEntry from a recommendation at a given
/// serving — shared by the confirm screen.
FoodEntry buildEntryFromRecommendation(
  FoodRecommendation rec, {
  required String userId,
  required double servingG,
  required String mealType,
}) {
  final scaled = rec.food.scaleToPortionG(servingG);
  final now = DateTime.now();
  return FoodEntry(
    id: 'rec_${now.microsecondsSinceEpoch}',
    userId: userId,
    logId: '${now.year}-${now.month}-${now.day}',
    foodId: rec.food.name,
    date: now,
    meal: scaled.name,
    quantity: servingG,
    unit: 'g',
    calories: scaled.energyKcal,
    protein: scaled.proteinG,
    carbs: scaled.carbsG,
    fat: scaled.fatG,
    ironMg: scaled.ironMg,
    notes: 'AI recommendation — ${rec.guideline.version}',
    mealType: mealType,
  );
}
