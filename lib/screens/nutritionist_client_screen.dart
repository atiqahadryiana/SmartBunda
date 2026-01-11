import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class NutritionistClientScreen extends ConsumerWidget {
  const NutritionistClientScreen({
    super.key,
    required this.client,
    required this.entries,
    required this.profile,
    required this.pregnancy,
  });

  final AppUser client;
  final List<FoodEntry> entries;
  final Profile? profile;
  final Pregnancy? pregnancy;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  _Targets _targets(Pregnancy? pregnancy) {
    final defaults = recommendedFor(pregnancy);
    return _Targets(
      calories: defaults.calories,
      protein: defaults.protein,
      ironMg: defaults.ironMg.toDouble(),
      folateMcg: defaults.folateMcg.toDouble(),
    );
  }

  List<_DaySummary> _lastDays(List<FoodEntry> entries, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(days, (index) {
      final day = start.subtract(Duration(days: index));
      final totals = _totals(
        entries.where((e) => _isSameDay(e.date, day)).toList(),
      );
      return _DaySummary(day: day, totals: totals);
    });
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(currentUserProvider);
    final canEditFeedback = viewer?.role == UserRole.doctor;
    final name = client.displayName ?? client.email;
    final sorted = List<FoodEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    final today = DateTime.now();
    final todayTotals = _totals(sorted.where((e) => _isSameDay(e.date, today)).toList());
    final targets = _targets(pregnancy);
    final week = _lastDays(sorted, 7);
    final last3 = week.take(3).toList();
    final lowProteinDays =
        last3.where((d) => d.totals.protein < targets.protein * 0.8).length;
    final lowCaloriesDays =
        last3.where((d) => d.totals.calories < targets.calories * 0.8).length;
    final noLogDays = last3.where((d) => d.totals.calories == 0).length;
    final insights = <String>[
      if (profile == null) 'Profile missing: targets use trimester defaults.',
      if (pregnancy == null) 'Pregnancy not set: targets use trimester defaults.',
      if (noLogDays >= 2) 'Missed logging on $noLogDays of the last 3 days.',
      if (lowCaloriesDays >= 2) 'Calories below target on $lowCaloriesDays of last 3 days.',
      if (lowProteinDays >= 2) 'Protein below target on $lowProteinDays of last 3 days.',
    ];

    return RequireSignIn(
      title: 'Client overview',
      showAppBar: true,
      message: 'Please sign in to view client details.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Client: $name'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ScreenHeader(
              title: 'Client overview',
              subtitle: 'Review profile, targets, and recent logs.',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text(client.email),
                trailing: Text(_roleLabel(client.role)),
              ),
            ),
            const SizedBox(height: 8),
            _ProfileCard(profile: profile, pregnancy: pregnancy),
            const SizedBox(height: 12),
            _ConditionFeedbackCard(
              profile: profile,
              canEdit: canEditFeedback,
              onEdit: () => _showConditionDialog(context, ref),
            ),
            const SizedBox(height: 16),
            Text('Targets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${targets.calories} kcal, ${targets.protein} g protein'),
                    Text('Iron ${targets.ironMg.toInt()} mg, Folate ${targets.folateMcg.toInt()} mcg'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${todayTotals.calories} / ${targets.calories} kcal'),
                    Text('${todayTotals.protein} / ${targets.protein} g protein'),
                    const SizedBox(height: 8),
                    _GapRow(
                      label: 'Iron',
                      intake: todayTotals.ironMg,
                      target: targets.ironMg,
                    ),
                    _GapRow(
                      label: 'Folate',
                      intake: todayTotals.folateMcg,
                      target: targets.folateMcg,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Insights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              const Text('No red flags in the last few days.')
            else
              Card(
                child: Column(
                  children: insights
                      .map(
                        (text) => ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(text),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            Text('Last 7 days', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: week.map((day) {
                  final status = day.totals.calories >= targets.calories * 0.8
                      ? 'On track'
                      : 'Low';
                  final color =
                      status == 'On track' ? Colors.green.shade600 : Colors.orange;
                  return ListTile(
                    dense: true,
                    title: Text('${day.day.month}/${day.day.day}'),
                    subtitle: Text(
                      '${day.totals.calories} kcal - ${day.totals.protein} g protein',
                    ),
                    trailing: Text(status, style: TextStyle(color: color)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Recent meals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (sorted.isEmpty)
              const Text('No meals logged yet.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length > 10 ? 10 : sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = sorted[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant_menu_outlined),
                      title: Text(entry.meal),
                      subtitle: Text('${entry.calories} kcal'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return role.label;
  }

  Future<void> _showConditionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile missing.')),
      );
      return;
    }
    final controller = TextEditingController(text: profile?.conditionNotes ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Condition feedback'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Notes for patient condition',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              await ref.read(dataStoreProvider).saveProfile(
                    profile!.copyWith(
                      conditionNotes: text.isEmpty ? null : text,
                    ),
                  );
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.pregnancy});

  final Profile? profile;
  final Pregnancy? pregnancy;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.warning_amber_outlined),
          title: Text('No profile on file'),
          subtitle: Text('Ask the client to complete their profile.'),
        ),
      );
    }

    final bmi = profile!.bmi;
    final conditions = <String>[
      if (profile!.medicalConditions.contains(MedicalCondition.gestationalDiabetes)) 'GDM',
      if (profile!.medicalConditions.contains(MedicalCondition.anemia)) 'Anemia',
    ];
    final conditionText = conditions.isEmpty ? 'None' : conditions.join(', ');
    final pregnancyLine = pregnancy == null
        ? 'Pregnancy not set'
        : '${_trimesterLabel(pregnancy!.trimesterEnum)} trimester - Week ${pregnancy!.gestationalWeek}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DOB: ${profile!.dob}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Blood type: ${profile!.bloodType}'),
            Text('BMI ${bmi.toStringAsFixed(1)}'),
            Text(pregnancyLine),
            Text('Conditions: $conditionText'),
          ],
        ),
      ),
    );
  }

  String _trimesterLabel(Trimester trimester) {
    switch (trimester) {
      case Trimester.first:
        return 'First';
      case Trimester.second:
        return 'Second';
      case Trimester.third:
        return 'Third';
    }
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.label,
    required this.intake,
    required this.target,
  });

  final String label;
  final double intake;
  final double target;

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 1 : intake / target;
    final isLow = ratio < 0.8;
    final status = isLow ? 'Low' : 'On track';
    final color = isLow ? Colors.orange : Colors.green.shade600;
    final targetText = target == 0 ? '' : ' / ${target.toStringAsFixed(0)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('$label: ${intake.toStringAsFixed(1)}$targetText')),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ConditionFeedbackCard extends StatelessWidget {
  const _ConditionFeedbackCard({
    required this.profile,
    required this.canEdit,
    required this.onEdit,
  });

  final Profile? profile;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final notes = profile?.conditionNotes?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Condition feedback', style: Theme.of(context).textTheme.titleSmall),
                if (canEdit)
                  TextButton(
                    onPressed: onEdit,
                    child: Text(notes.isEmpty ? 'Add' : 'Update'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(notes.isEmpty ? 'No feedback yet.' : notes),
          ],
        ),
      ),
    );
  }
}

class _Targets {
  _Targets({
    required this.calories,
    required this.protein,
    required this.ironMg,
    required this.folateMcg,
  });

  final int calories;
  final int protein;
  final double ironMg;
  final double folateMcg;
}

class _EntryTotals {
  _EntryTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ironMg,
    required this.folateMcg,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double ironMg;
  final double folateMcg;
}

class _DaySummary {
  _DaySummary({required this.day, required this.totals});

  final DateTime day;
  final _EntryTotals totals;
}
