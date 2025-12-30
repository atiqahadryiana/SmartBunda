import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/food_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/screen_header.dart';
import 'profile_screen.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  double _dayOffset = 0;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final profileAsync = ref.watch(profileProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);
    const maxDayOffset = 30.0;

    final dayLabel = DateFormat.MMMd().format(_selectedDate);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Summary')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Summary',
              subtitle: 'Review nutrition progress and recommendations by day.',
              icon: Icons.dashboard_outlined,
              action: IconButton(
                tooltip: 'Pick date',
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final offset = DateTime.now()
                        .difference(picked)
                        .inDays
                        .toDouble()
                        .clamp(0.0, maxDayOffset);
                    setState(() {
                      _selectedDate = picked;
                      _dayOffset = offset;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 8),
            Text('Viewing: $dayLabel'),
            if (profileAsync.valueOrNull == null)
              Card(
                color: const Color(0xFFFFF1F5),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.pink),
                  title: const Text('Complete your profile to tailor targets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(showAppBar: true),
                    ),
                  ),
                ),
              ),
            Slider(
              min: 0,
              max: maxDayOffset,
              divisions: maxDayOffset.toInt(),
              label: '${_dayOffset.toInt()} days ago',
              value: _dayOffset,
              activeColor: Colors.pinkAccent,
              onChanged: (v) {
                final newDate = DateTime.now().subtract(Duration(days: v.toInt()));
                setState(() {
                  _dayOffset = v;
                  _selectedDate = newDate;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.when(
                data: (items) {
                  final todays =
                      items.where((e) => _isSameDay(e.date, _selectedDate)).toList();
                  final profile = profileAsync.valueOrNull;
                  final pregnancy = pregnancyAsync.valueOrNull;
                  final targets = _targets(pregnancy);
                  final totals = _totals(todays);
                  final gaps = _gaps(totals, targets);
                  final recs = _recommendations(profile, gaps);
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricCard(
                          label: 'Calories',
                          value: '${totals.calories} / ${targets.calories} kcal',
                          color: const Color(0xFFF48FB1),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Protein',
                                value: '${totals.protein} / ${targets.protein} g',
                                color: Colors.pinkAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricCard(
                                label: 'Carbs',
                                value: '${totals.carbs} g',
                                color: Colors.pink.shade200,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricCard(
                                label: 'Fat',
                                value: '${totals.fat} g',
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MicroGaps(gaps: gaps),
                        const SizedBox(height: 16),
                        Text(
                          'Recommendations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (recs.isEmpty)
                          const Text('On track. Keep logging meals.')
                        else
                          ...recs.map((r) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('- '),
                                    Expanded(child: Text(r)),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 16),
                        Text(
                          'Entries ($dayLabel)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        todays.isEmpty
                            ? const Text('Nothing logged for this day.')
                            : Column(
                                children: todays
                                    .map(
                                      (e) => Card(
                                        child: ListTile(
                                          title: Text(e.meal),
                                          subtitle: Text(
                                            '${e.calories} kcal | P ${e.protein}g | C ${e.carbs}g | F ${e.fat}g',
                                          ),
                                          trailing: Text(DateFormat.Md().format(e.date)),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  _EntryTotals _totals(List<FoodEntry> entries) {
    var calories = 0, protein = 0, carbs = 0, fat = 0;
    double iron = 0, folate = 0;
    for (final e in entries) {
      calories += e.calories;
      protein += e.protein;
      carbs += e.carbs;
      fat += e.fat;
      iron += e.ironMg;
      folate += e.folateMcg;
    }
    return _EntryTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      ironMg: iron,
      folateMcg: folate,
    );
  }

  _EntryTotals _targets(Pregnancy? pregnancy) {
    final defaults = recommendedFor(pregnancy);
    return _EntryTotals(
      calories: defaults.calories,
      protein: defaults.protein,
      carbs: 0,
      fat: 0,
      ironMg: defaults.ironMg.toDouble(),
      folateMcg: defaults.folateMcg.toDouble(),
    );
  }

  List<_Gap> _gaps(_EntryTotals totals, _EntryTotals targets) {
    return [
      _Gap(label: 'Iron', intake: totals.ironMg, target: targets.ironMg),
      _Gap(label: 'Folate', intake: totals.folateMcg, target: targets.folateMcg),
    ];
  }

  List<String> _recommendations(Profile? profile, List<_Gap> gaps) {
    final recs = <String>[];
    for (final gap in gaps) {
      if (gap.isLow) {
        switch (gap.label) {
          case 'Iron':
            recs.add('Add spinach, legumes, and lean meat for iron support.');
            break;
          case 'Folate':
            recs.add('Add leafy greens or beans to raise folate intake.');
            break;
        }
      }
    }
    if (profile != null && profile.medicalConditions.contains(MedicalCondition.anemia)) {
      recs.add('For anemia: pair iron sources with vitamin C to improve absorption.');
    }
    return recs;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color.withValues(alpha: 230);
    return Card(
      color: color.withValues(alpha: 31),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTotals {
  _EntryTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ironMg = 0,
    this.folateMcg = 0,
  });
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double ironMg;
  final double folateMcg;
}

class _Gap {
  _Gap({
    required this.label,
    required this.intake,
    required this.target,
  });

  final String label;
  final double intake;
  final double target;

  double get ratio => target == 0 ? 1 : intake / target;
  bool get isLow => ratio < 0.8;
  bool get isOnTrack => ratio >= 0.8;
}

class _MicroGaps extends StatelessWidget {
  const _MicroGaps({required this.gaps});
  final List<_Gap> gaps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: gaps.map((g) {
        final status = g.isOnTrack ? 'On track' : 'Low';
        final color = g.isOnTrack ? Colors.green.shade600 : Colors.orange;
        final targetText = g.target == 0 ? '' : ' / ${g.target.toStringAsFixed(0)}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text('${g.label}: ${g.intake.toStringAsFixed(1)}$targetText'),
              ),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
