/// SmartBunda — Food Analysis History
///
/// Lists the patient's past AI food-analysis events (food, recognition
/// confidence, image-quality score, calories, date).
library smartbunda.food_history_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/food_history_entry.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/theme/app_theme.dart';

class FoodHistoryScreen extends ConsumerWidget {
  const FoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final historyAsync = ref.watch(foodHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Food History'))),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(strings.t('Could not load history.')),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyHistory(strings: strings);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _HistoryTile(entry: items[index]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final FoodHistoryEntry entry;

  Color _confidenceColor() {
    if (entry.confidenceScore >= 80) return AppTheme.success;
    if (entry.confidenceScore >= 50) return AppTheme.warning;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.blushGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: AppTheme.darkPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.calories} kcal · ${DateFormat('d MMM yyyy, HH:mm').format(entry.analysisDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _Chip(
                      label: 'Confidence ${entry.confidenceScore}%',
                      color: _confidenceColor(),
                    ),
                    _Chip(
                      label: 'Quality ${entry.qualityScore}/100',
                      color: AppTheme.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 80)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.blushGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.history,
                  color: AppTheme.darkPink, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              strings.t('No food analyses yet'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.t(
                  'Scan a meal to see your analysis history here.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
