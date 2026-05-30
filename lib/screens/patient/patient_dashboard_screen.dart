import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/theme/app_theme.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/screens/appointments/appointments_screen.dart';
import 'package:smartbunda/screens/food/hydration_screen.dart';
import 'package:smartbunda/screens/log/log_screen.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/hydration_entry.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/utils/nutrition_guides.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenRiskAssessment,
    required this.onOpenEducation,
    required this.onLogout,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenRiskAssessment;
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
    final targets = recommendedFor(pregnancy, profile: profile);
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
                        color: AppTheme.darkPink,
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
                        color: AppTheme.healthcareTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _QuickActionsBar(onOpenTab: onOpenTab),
                const SizedBox(height: 16),
                _ReadinessCard(
                  profile: profile,
                  pregnancy: pregnancy,
                  onOpen: onOpenRiskAssessment,
                ),
                const SizedBox(height: 16),
                _ClinicalAlertsCard(profile: profile, pregnancy: pregnancy),
                const SizedBox(height: 16),
                _NutritionCard(totals: totals, targets: targets),
                const SizedBox(height: 16),
                _AppointmentCard(
                  appointment: upcoming.isEmpty ? null : upcoming.first,
                  onView: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppointmentsScreen(role: UserRole.patient),
                    ),
                  ),
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
        gradient: AppTheme.heroGradient,
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
                        color: AppTheme.darkPink.withValues(alpha: 25),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.darkPink,
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
                  color: AppTheme.primaryPink,
                ),
                _StatusPill(
                  icon: Icons.pregnant_woman_outlined,
                  label: pregnancy == null
                      ? 'Pregnancy not set'
                      : 'Week ${pregnancy!.gestationalWeek}',
                  color: AppTheme.info,
                ),
                _StatusPill(
                  icon: Icons.verified_outlined,
                  label: pregnancy?.riskLevel ?? 'Stable',
                  color: AppTheme.healthcareTeal,
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
    final carbsTarget = (targets.calories * targets.carbPct / 4).round();
    final fatTarget = (targets.calories * targets.fatPct / 9).round();

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
                      color: AppTheme.healthcareTeal,
                    ),
                    _MacroLegendRow(
                      label: 'Carbs',
                      value: totals.carbs,
                      target: carbsTarget,
                      color: AppTheme.info,
                    ),
                    _MacroLegendRow(
                      label: 'Fats',
                      value: totals.fat,
                      target: fatTarget,
                      color: AppTheme.darkPink,
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
      ..color = const Color(0xFFFCE4EC)
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
      AppTheme.healthcareTeal,
      AppTheme.info,
      AppTheme.darkPink,
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
        gradient: AppTheme.blushGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.darkPink),
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

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.profile,
    required this.pregnancy,
    required this.onOpen,
  });

  final Profile? profile;
  final Pregnancy? pregnancy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final bmi = profile?.bmi;
    final riskLabel = pregnancy?.riskLevel.trim().isNotEmpty == true
        ? pregnancy!.riskLevel
        : _bmiRiskLabel(bmi);
    final riskColor = riskLabel.toLowerCase().contains('high')
        ? AppTheme.errorColor
        : riskLabel.toLowerCase().contains('review') ||
                riskLabel.toLowerCase().contains('moderate')
            ? AppTheme.warning
            : AppTheme.healthcareTeal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF8BBD0)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withValues(alpha: 20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.health_and_safety_outlined, color: riskColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-pregnancy readiness',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assess risks, pregnancy intention, referrals, and follow-up before conception.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF59677D),
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(
                          icon: Icons.monitor_weight_outlined,
                          label: bmi == null
                              ? 'BMI pending'
                              : 'BMI ${bmi.toStringAsFixed(1)}',
                        ),
                        _MiniChip(
                          icon: Icons.flag_outlined,
                          label: riskLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static String _bmiRiskLabel(double? bmi) {
    if (bmi == null) return 'Assessment needed';
    if (bmi >= 30) return 'Risk review';
    if (bmi < 18.5) return 'Nutrition review';
    return 'Stable';
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBase,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.darkPink),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF8BBD0)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Quick Actions bar ─────────────────────────────────────────────────────────

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _QuickAction(
            icon: Icons.center_focus_strong,
            label: 'Scan Food',
            isPrimary: true,
            onTap: () => onOpenTab(1), // tab 1 = Scan
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _QuickAction(
            icon: Icons.restaurant_outlined,
            label: 'Log Meal',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _QuickAction(
            icon: Icons.water_drop_outlined,
            label: 'Log Water',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HydrationScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkPink.withValues(alpha: 60),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF8BBD0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.darkPink, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.darkPink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalAlert {
  const _ClinicalAlert({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final _ClinicalAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.color.withValues(alpha: 70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alert.icon, color: alert.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: alert.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(alert.body, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalAlertsCard extends StatelessWidget {
  const _ClinicalAlertsCard({required this.profile, required this.pregnancy});

  final Profile? profile;
  final Pregnancy? pregnancy;

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts();
    if (alerts.isEmpty) return const SizedBox.shrink();
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.notifications_active_outlined,
            title: 'Clinical alerts',
          ),
          const SizedBox(height: 10),
          ...alerts.map((alert) => _AlertTile(alert: alert)),
        ],
      ),
    );
  }

  List<_ClinicalAlert> _buildAlerts() {
    final alerts = <_ClinicalAlert>[];
    final hb = profile?.hemoglobinGdl;

    // IDA: Hb < 11.0 g/dL → 120 mg elemental iron
    if (hb != null && hb < 11.0) {
      alerts.add(const _ClinicalAlert(
        icon: Icons.bloodtype_outlined,
        title: 'Iron Deficiency Anaemia',
        body:
            'Hb < 11.0 g/dL detected. Increase daily oral iron to 120 mg of elemental iron. Follow up with your doctor.',
        color: AppTheme.darkPink,
      ));
    }

    // Gestational diabetes → specific macro distribution
    if (profile?.medicalConditions
            .contains(MedicalCondition.gestationalDiabetes) ??
        false) {
      alerts.add(const _ClinicalAlert(
        icon: Icons.monitor_heart_outlined,
        title: 'Gestational Diabetes',
        body:
            'Recommended macros: 45–60% carbohydrates · 15–20% protein · 25–35% fat.',
        color: AppTheme.warning,
      ));
    }

    // General pregnancy supplement reminder
    if (pregnancy != null) {
      alerts.add(const _ClinicalAlert(
        icon: Icons.medication_outlined,
        title: 'Pregnancy Supplements',
        body: 'Take 30–60 mg iron · 200 μg iodine · 1000 mg calcium daily.',
        color: AppTheme.healthcareTeal,
      ));
    }

    return alerts;
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
