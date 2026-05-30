import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/hydration_entry.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/nutrition_guides.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _addWater(int amountMl) async {
    final user = ref.read(currentUserProvider);
    if (user == null || amountMl <= 0) return;
    final entry = HydrationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: user.id,
      date: DateTime.now(),
      amountMl: amountMl,
    );
    await ref.read(dataStoreProvider).addHydrationEntry(entry);
  }

  int _waterTarget(Pregnancy? pregnancy) {
    return recommendedFor(pregnancy).waterMl;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeLabel(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<_DayTotal> _lastDays(List<HydrationEntry> entries, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(days, (index) {
      final day = start.subtract(Duration(days: index));
      final total = entries.fold<int>(
        0,
        (sum, entry) => _isSameDay(entry.date, day) ? sum + entry.amountMl : sum,
      );
      return _DayTotal(day: day, totalMl: total);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final strings = AppStrings.of(context);

    final pregnancyAsync = ref.watch(pregnancyProvider);
    final hydrationAsync = ref.watch(hydrationEntriesProvider);

    final child = user == null
        ? const SizedBox.shrink()
        : Scaffold(
            appBar: AppBar(title: Text(strings.t('Hydration'))),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: hydrationAsync.when(
                data: (entries) {
                  final pregnancy = pregnancyAsync.valueOrNull;
                  final target = _waterTarget(pregnancy);
                  final today = DateTime.now();
                  final todayEntries = entries
                      .where((e) => _isSameDay(e.date, today))
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  final total = todayEntries.fold<int>(0, (sum, e) => sum + e.amountMl);
                  final progress = target == 0 ? 0.0 : (total / target).clamp(0.0, 1.0);
                  final history = _lastDays(entries, 7);

                  return ListView(
                    children: [
                      ScreenHeader(
                        title: strings.t('Hydration'),
                        subtitle: strings.t(
                          'Log water throughout the day to hit your daily target.',
                        ),
                        icon: Icons.water_drop_outlined,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(strings.t('Today'),
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('$total / $target ml'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: progress),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(strings.t('Quick add'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _addWater(250),
                            child: const Text('+250 ml'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _addWater(500),
                            child: const Text('+500 ml'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _addWater(750),
                            child: const Text('+750 ml'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  InputDecoration(labelText: strings.t('Custom amount (ml)')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final value = int.tryParse(_customCtrl.text);
                              if (value == null || value <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.t('Enter a valid amount in ml')),
                                  ),
                                );
                                return;
                              }
                              _customCtrl.clear();
                              FocusScope.of(context).unfocus();
                              _addWater(value);
                            },
                            child: Text(strings.t('Add')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(strings.t('Today log'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (todayEntries.isEmpty)
                        EmptyState(
                          icon: Icons.water_drop_outlined,
                          title: strings.t('No water logged yet'),
                          message:
                              strings.t('Use the quick add buttons to log your first drink.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todayEntries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = todayEntries[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.water_drop_outlined),
                                title: Text('${entry.amountMl} ml'),
                                subtitle: Text(_timeLabel(entry.date)),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Text(strings.t('Last 7 days'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: history
                              .map(
                                (day) => ListTile(
                                  dense: true,
                                  title: Text('${day.day.month}/${day.day.day}'),
                                  trailing: Text('${day.totalMl} ml'),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          );

    return RequireSignIn(
      title: strings.t('Hydration'),
      showAppBar: true,
      message: strings.t('Please sign in to track hydration.'),
      child: child,
    );
  }
}

class _DayTotal {
  const _DayTotal({required this.day, required this.totalMl});

  final DateTime day;
  final int totalMl;
}
