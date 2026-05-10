import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../localization/app_strings.dart';
import '../models/food_entry.dart';
import '../models/firestore_doc.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';
import 'edit_profile_screen.dart';

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
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    const maxDayOffset = 30.0;

    final dayLabel = DateFormat.MMMd().format(_selectedDate);

    return RequireSignIn(
      title: strings.t('Summary'),
      showAppBar: widget.showAppBar,
      message: strings.t('Please sign in to view your summary.'),
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: Text(strings.t('Summary')))
            : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: strings.t('Summary'),
                subtitle: strings
                    .t('Review nutrition progress and recommendations by day.'),
                icon: Icons.dashboard_outlined,
                action: IconButton(
                  tooltip: strings.t('Pick date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
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
              Text(strings.viewingDay(dayLabel)),
              if (profileAsync.valueOrNull == null)
                Card(
                  color: Color.alphaBlend(
                    scheme.secondary.withValues(alpha: 45),
                    scheme.surface,
                  ),
                  child: ListTile(
                    leading: Icon(Icons.person, color: scheme.primary),
                    title: Text(
                        strings.t('Complete your profile to tailor targets')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const EditProfileScreen(showAppBar: true),
                      ),
                    ),
                  ),
                ),
              Slider(
                min: 0,
                max: maxDayOffset,
                divisions: maxDayOffset.toInt(),
                label: strings.daysAgo(_dayOffset.toInt()),
                value: _dayOffset,
                activeColor: scheme.primary,
                onChanged: (v) {
                  final newDate =
                      DateTime.now().subtract(Duration(days: v.toInt()));
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
                    final todays = items
                        .where((e) => _isSameDay(e.date, _selectedDate))
                        .toList();
                    final profile = profileAsync.valueOrNull;
                    final pregnancy = pregnancyAsync.valueOrNull;
                    final targets = _targets(pregnancy);
                    final totals = _totals(todays);
                    final gaps = _gaps(totals, targets);
                    final dbRecs = _recommendationsFromDocs(
                      recommendationsAsync.valueOrNull ??
                          const <FirestoreDoc>[],
                    );
                    final computedRecs =
                        _recommendations(profile, gaps, strings);
                    final recs = dbRecs.isNotEmpty ? dbRecs : computedRecs;
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NutrientSplitCard(
                            totals: totals,
                            targets: targets,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.t('Recommendations'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (recs.isEmpty)
                            Text(strings.t('On track. Keep logging meals.'))
                          else
                            ...recs.map((r) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('- '),
                                      Expanded(child: Text(r)),
                                    ],
                                  ),
                                )),
                          const SizedBox(height: 16),
                          Text(
                            strings.entriesForDay(dayLabel),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          todays.isEmpty
                              ? Text(strings.t('Nothing logged for this day.'))
                              : Column(
                                  children: todays
                                      .map(
                                        (e) => Card(
                                          child: ListTile(
                                            title: Text(e.meal),
                                            subtitle: Text(
                                              '${e.calories} kcal | P ${e.protein}g | C ${e.carbs}g | F ${e.fat}g | ${_mealTypeLabel(e.mealType ?? _mealTypeFromDate(e.date), strings)}',
                                            ),
                                            trailing: Text(
                                                DateFormat.Md().format(e.date)),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
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
    final carbTarget =
        (defaults.calories * 0.5 / 4).round(); // 50% calories from carbs
    final fatTarget =
        (defaults.calories * 0.3 / 9).round(); // 30% calories from fat
    return _EntryTotals(
      calories: defaults.calories,
      protein: defaults.protein,
      carbs: carbTarget,
      fat: fatTarget,
      ironMg: defaults.ironMg.toDouble(),
      folateMcg: defaults.folateMcg.toDouble(),
    );
  }

  List<_Gap> _gaps(_EntryTotals totals, _EntryTotals targets) {
    return [
      _Gap(label: 'Iron', intake: totals.ironMg, target: targets.ironMg),
      _Gap(
          label: 'Folate', intake: totals.folateMcg, target: targets.folateMcg),
    ];
  }

  List<String> _recommendations(
    Profile? profile,
    List<_Gap> gaps,
    AppStrings strings,
  ) {
    final recs = <String>[];
    for (final gap in gaps) {
      if (gap.isLow) {
        switch (gap.label) {
          case 'Iron':
            recs.add(
              strings
                  .t('Add spinach, legumes, and lean meat for iron support.'),
            );
            break;
          case 'Folate':
            recs.add(
                strings.t('Add leafy greens or beans to raise folate intake.'));
            break;
        }
      }
    }
    if (profile != null &&
        profile.medicalConditions.contains(MedicalCondition.anemia)) {
      recs.add(
        strings.t(
            'For anemia: pair iron sources with vitamin C to improve absorption.'),
      );
    }
    return recs;
  }

  List<String> _recommendationsFromDocs(List<FirestoreDoc> docs) {
    final recs = <String>[];
    for (final doc in docs) {
      final data = doc.data;
      final text = _stringOrNull(data['recommendation']) ??
          _stringOrNull(data['text']) ??
          _stringOrNull(data['message']) ??
          _stringOrNull(data['title']) ??
          _stringOrNull(data['name']) ??
          doc.title ??
          doc.id;
      if (text.isNotEmpty) {
        recs.add(text);
      }
    }
    return recs;
  }

  String? _stringOrNull(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _mealTypeFromDate(DateTime date) {
    final hour = date.hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 20) return 'dinner';
    return 'supper';
  }

  String _mealTypeLabel(String? value, AppStrings strings) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'breakfast':
        return strings.t('Breakfast');
      case 'lunch':
        return strings.t('Lunch');
      case 'dinner':
        return strings.t('Dinner');
      case 'supper':
        return strings.t('Supper');
      default:
        return strings.t('Meal');
    }
  }
}

class _NutrientSplitCard extends StatelessWidget {
  const _NutrientSplitCard({
    required this.totals,
    required this.targets,
  });

  final _EntryTotals totals;
  final _EntryTotals targets;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final segments = _nutrientSegments(totals, targets, strings);
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    final empty = total <= 0;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 140);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('Nutrient progress mix'), style: titleStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: _MacroPieChart(
                    segments: segments,
                    empty: empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (empty)
                        Text(
                          strings.t('No nutrients logged yet.'),
                          style: TextStyle(color: muted),
                        )
                      else ...[
                        Text(strings.t('Progress by target'),
                            style: TextStyle(color: muted)),
                        const SizedBox(height: 6),
                        ...segments.map(
                          (segment) => _MacroLegendItem(
                            label: segment.label,
                            intake: segment.intake,
                            target: segment.target,
                            color: segment.color,
                            percent:
                                total == 0 ? 0 : (segment.value / total * 100),
                            unit: segment.unit,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_MacroSegment> _nutrientSegments(
    _EntryTotals totals,
    _EntryTotals targets,
    AppStrings strings,
  ) {
    return [
      _MacroSegment(
        label: strings.t('Calories'),
        value: 0,
        intake: totals.calories.toDouble(),
        target: targets.calories.toDouble(),
        unit: 'kcal',
        color: Colors.red.shade300,
      ),
      _MacroSegment(
        label: strings.t('Protein'),
        value: 0,
        intake: totals.protein.toDouble(),
        target: targets.protein.toDouble(),
        unit: 'g',
        color: Colors.redAccent,
      ),
      _MacroSegment(
        label: strings.t('Carbs'),
        value: 0,
        intake: totals.carbs.toDouble(),
        target: targets.carbs.toDouble(),
        unit: 'g',
        color: Colors.red.shade400.withValues(alpha: 180),
      ),
      _MacroSegment(
        label: strings.t('Fat'),
        value: 0,
        intake: totals.fat.toDouble(),
        target: targets.fat.toDouble(),
        unit: 'g',
        color: Colors.deepOrange.shade300,
      ),
      _MacroSegment(
        label: strings.t('Iron'),
        value: 0,
        intake: totals.ironMg,
        target: targets.ironMg,
        unit: 'mg',
        color: Colors.red.shade700,
      ),
      _MacroSegment(
        label: strings.t('Folate'),
        value: 0,
        intake: totals.folateMcg,
        target: targets.folateMcg,
        unit: 'mcg',
        color: Colors.orange.shade300,
      ),
    ].map(_withProgress).whereType<_MacroSegment>().toList();
  }

  _MacroSegment? _withProgress(_MacroSegment segment) {
    if (segment.target <= 0) return null;
    final progress = (segment.intake / segment.target).clamp(0.0, 1.2);
    return segment.copyWith(value: progress);
  }
}

class _MacroLegendItem extends StatelessWidget {
  const _MacroLegendItem({
    required this.label,
    required this.intake,
    required this.target,
    required this.color,
    required this.percent,
    required this.unit,
  });

  final String label;
  final double intake;
  final double target;
  final Color color;
  final double percent;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 150);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '${intake.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
            style: TextStyle(color: muted),
          ),
          const SizedBox(width: 8),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _MacroPieChart extends StatelessWidget {
  const _MacroPieChart({
    required this.segments,
    required this.empty,
  });

  final List<_MacroSegment> segments;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 120);
    final average = segments.isEmpty ? 0 : (total / segments.length * 100);
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: _PieChartPainter(
            segments: segments,
            empty: empty,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              empty ? '0%' : '${average.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(strings.t('avg'), style: TextStyle(color: muted)),
          ],
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.segments,
    required this.empty,
  });

  final List<_MacroSegment> segments;
  final bool empty;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = Colors.black12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);

    if (empty) return;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var startAngle = -1.5707963267948966;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * 6.283185307179586;
      stroke.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        stroke,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.empty != empty;
  }
}

class _MacroSegment {
  const _MacroSegment({
    required this.label,
    required this.value,
    required this.color,
    required this.intake,
    required this.target,
    required this.unit,
  });

  final String label;
  final double value;
  final Color color;
  final double intake;
  final double target;
  final String unit;

  _MacroSegment copyWith({
    double? value,
  }) {
    return _MacroSegment(
      label: label,
      value: value ?? this.value,
      color: color,
      intake: intake,
      target: target,
      unit: unit,
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
