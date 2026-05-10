import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../models/food_entry.dart';
import '../models/hydration_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../utils/nutrition_guides.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenEducation,
    required this.onLogout,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenEducation;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final pregnancy = ref.watch(pregnancyProvider).valueOrNull;
    final entries =
        ref.watch(entriesProvider).valueOrNull ?? const <FoodEntry>[];
    final hydration = ref.watch(hydrationEntriesProvider).valueOrNull ??
        const <HydrationEntry>[];
    final appointments =
        ref.watch(appointmentsProvider).valueOrNull ?? const <Appointment>[];
    final todayEntries =
        entries.where((entry) => _isToday(entry.date)).toList();
    final todayWater = hydration
        .where((entry) => _isToday(entry.date))
        .fold<int>(0, (sum, entry) => sum + entry.amountMl);
    final totals = _DailyTotals.fromEntries(todayEntries);
    final targets = recommendedFor(pregnancy);
    final waterTarget = targets.waterMl;
    final upcoming = appointments
        .where((item) =>
            item.dateTime.isAfter(DateTime.now()) &&
            item.status.toUpperCase() != 'CANCELLED')
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              name: user?.displayName ?? user?.email ?? 'Mother',
              profile: profile,
              pregnancy: pregnancy,
              onOpenEducation: onOpenEducation,
              onLogout: onLogout,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Calories',
                        value: '${totals.calories}',
                        unit: 'kcal',
                        progress: _ratio(totals.calories, targets.calories),
                        color: const Color(0xFFE86D9B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.water_drop_outlined,
                        title: 'Water',
                        value: '${(todayWater / 1000).toStringAsFixed(1)}L',
                        unit: '/ ${(waterTarget / 1000).toStringAsFixed(1)}L',
                        progress: _ratio(todayWater, waterTarget),
                        color: const Color(0xFF23A6A6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _NutritionCard(totals: totals, targets: targets),
                const SizedBox(height: 16),
                _AppointmentCard(
                  appointment: upcoming.isEmpty ? null : upcoming.first,
                  onView: () => onOpenTab(3),
                ),
                const SizedBox(height: 16),
                _ActivityCard(entries: todayEntries, waterMl: todayWater),
                const SizedBox(height: 16),
                const _TipCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static double _ratio(num value, num target) {
    if (target <= 0) return 0;
    return (value / target).clamp(0.0, 1.0).toDouble();
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    required this.profile,
    required this.pregnancy,
    required this.onOpenEducation,
    required this.onLogout,
  });

  final String name;
  final Profile? profile;
  final Pregnancy? pregnancy;
  final VoidCallback onOpenEducation;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EE), Color(0xFFE7F6FF), Color(0xFFF1E8FF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 225),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE86D9B).withValues(alpha: 20),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFC24879),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF253144),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your health and nutrition overview for today.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF59677D),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderIconButton(
                  tooltip: 'Education',
                  icon: Icons.menu_book_outlined,
                  onPressed: onOpenEducation,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  tooltip: 'Logout',
                  icon: Icons.logout,
                  onPressed: onLogout,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusPill(
                  icon: Icons.monitor_weight_outlined,
                  label: profile == null
                      ? 'Profile pending'
                      : '${profile!.currentWeightKg.toStringAsFixed(1)} kg',
                  color: const Color(0xFFE86D9B),
                ),
                _StatusPill(
                  icon: Icons.pregnant_woman_outlined,
                  label: pregnancy == null
                      ? 'Pregnancy not set'
                      : 'Week ${pregnancy!.gestationalWeek}',
                  color: const Color(0xFF8A7CF6),
                ),
                _StatusPill(
                  icon: Icons.verified_outlined,
                  label: pregnancy?.riskLevel ?? 'Stable',
                  color: const Color(0xFF23A6A6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 215),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 21, color: const Color(0xFF302333)),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: color.withValues(alpha: 28),
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.totals, required this.targets});

  final _DailyTotals totals;
  final RecommendedTargets targets;

  @override
  Widget build(BuildContext context) {
    final proteinTarget = targets.protein;
    final carbsTarget = (targets.calories * 0.5 / 4).round();
    final fatTarget = (targets.calories * 0.3 / 9).round();

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.pie_chart_outline, title: 'Nutrition progress'),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _MacroPiePainter(
                    protein: totals.protein,
                    carbs: totals.carbs,
                    fat: totals.fat,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${totals.calories}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          'kcal',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _MacroLegendRow(
                      label: 'Protein',
                      value: totals.protein,
                      target: proteinTarget,
                      color: const Color(0xFF23A6A6),
                    ),
                    _MacroLegendRow(
                      label: 'Carbs',
                      value: totals.carbs,
                      target: carbsTarget,
                      color: const Color(0xFF8A7CF6),
                    ),
                    _MacroLegendRow(
                      label: 'Fats',
                      value: totals.fat,
                      target: fatTarget,
                      color: const Color(0xFFE86D9B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  const _MacroLegendRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            '$value / $target g',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MacroPiePainter extends CustomPainter {
  const _MacroPiePainter({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int protein;
  final int carbs;
  final int fat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = size.shortestSide * 0.18;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = const Color(0xFFF0E8EE)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, basePaint);

    final values = [
      protein * 4.0,
      carbs * 4.0,
      fat * 9.0,
    ];
    final total = values.fold<double>(0, (sum, item) => sum + item);
    if (total <= 0) return;

    final colors = [
      const Color(0xFF23A6A6),
      const Color(0xFF8A7CF6),
      const Color(0xFFE86D9B),
    ];
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroPiePainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat;
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onView});

  final Appointment? appointment;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.event_available, title: 'Upcoming appointment'),
          const SizedBox(height: 10),
          if (appointment == null)
            Text('No upcoming appointment. Book a visit when you need support.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                  child: Icon(Icons.medical_services_outlined)),
              title: Text(appointment!.type),
              subtitle: Text(
                DateFormat('EEE, d MMM, h:mm a').format(appointment!.dateTime),
              ),
              trailing: Text(appointment!.status),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: onView, child: const Text('View appointment')),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entries, required this.waterMl});

  final List<FoodEntry> entries;
  final int waterMl;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.history, title: 'Recent health activity'),
          const SizedBox(height: 10),
          _ActivityRow(
              icon: Icons.restaurant_outlined,
              title: '${entries.length} meals logged today',
              subtitle: entries.isEmpty
                  ? 'Start by logging breakfast or lunch.'
                  : entries.last.meal),
          _ActivityRow(
              icon: Icons.water_drop_outlined,
              title: '$waterMl ml water logged',
              subtitle: 'Keep sipping through the day.'),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE3EE), Color(0xFFE8FAF8)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFC24879)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Pair iron-rich foods with vitamin C to support better absorption.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 8),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DailyTotals {
  const _DailyTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory _DailyTotals.fromEntries(List<FoodEntry> entries) {
    return _DailyTotals(
      calories: entries.fold(0, (sum, entry) => sum + entry.calories),
      protein: entries.fold(0, (sum, entry) => sum + entry.protein),
      carbs: entries.fold(0, (sum, entry) => sum + entry.carbs),
      fat: entries.fold(0, (sum, entry) => sum + entry.fat),
    );
  }
}
