import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/screen_header.dart';
import 'package:smartbunda/screens/food/food_scan_screen.dart';
import 'package:smartbunda/screens/log/meal_log_actions.dart';
import 'package:smartbunda/screens/log/meal_log_utils.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('Meal log')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: strings.t('Meal log'),
              subtitle: strings.t(
                  'Log meals to keep your summary and recommendations accurate.'),
              icon: Icons.restaurant_menu,
              action: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FoodScanScreen()),
                ),
                icon: const Icon(Icons.center_focus_strong),
                label: Text(strings.t('Scan meal')),
              ),
            ),
            const SizedBox(height: 16),
            _QuickLogActions(ref: ref),
            const SizedBox(height: 12),
            Expanded(
              child: entries.when(
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: Icons.restaurant_menu_outlined,
                        title: strings.t('No meals logged yet'),
                        message: strings.t(
                            'Add your first meal to start tracking nutrition.'),
                        action: FilledButton.icon(
                          onPressed: () =>
                              MealLogActions.showAddOptions(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(strings.t('Log a meal')),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading:
                                  const Icon(Icons.restaurant_menu_outlined),
                              title: Text(entry.meal),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _MealChip('${entry.calories} kcal'),
                                    _MealChip('P ${entry.protein}g'),
                                    _MealChip('C ${entry.carbs}g'),
                                    _MealChip('F ${entry.fat}g'),
                                    _MealChip(
                                      mealTypeLabel(
                                        entry.mealType ??
                                            mealTypeFromDate(entry.date),
                                        strings,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${entry.date.day}/${entry.date.month}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: strings.t('Meal options'),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        MealLogActions.editEntrySheet(
                                            context, ref, entry);
                                      } else if (value == 'delete') {
                                        MealLogActions.confirmDeleteEntry(
                                            context, ref, entry);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_outlined,
                                                size: 20),
                                            const SizedBox(width: 12),
                                            Text(strings.t('Edit')),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline,
                                                size: 20),
                                            const SizedBox(width: 12),
                                            Text(strings.t('Delete')),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogActions extends StatelessWidget {
  const _QuickLogActions({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Search-style entry into the food database picker (left-aligned, like
        // a real search bar so it doesn't read as a centered button).
        Expanded(
          child: InkWell(
            onTap: () => MealLogActions.showFoodPicker(context, ref),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    strings.t('Search the food database'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: strings.t('Scan meal'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FoodScanScreen()),
          ),
          icon: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
