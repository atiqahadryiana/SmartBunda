import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/theme/app_theme.dart';

import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/screens/food/food_scan_screen.dart';
import 'package:smartbunda/screens/patient/notifications_screen.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/hydration_entry.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/nutrition_guides.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenRiskAssessment,
    required this.onOpenAssessments,
    required this.onOpenEducation,
    required this.onLogout,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenRiskAssessment;
  final VoidCallback onOpenAssessments;
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
    final alerts = ref.watch(alertsProvider).valueOrNull ?? const <AlertItem>[];
    final unreadAlerts =
        alerts.where((a) => a.status.toUpperCase() != 'READ').length;
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

    // Raise a notification when today's calories exceed the target. Idempotent:
    // one alert per patient per day (deterministic id), guarded so a rebuild
    // doesn't re-write it.
    final caloriesTarget = targets.calories.round();
    if (user != null &&
        caloriesTarget > 0 &&
        totals.calories > caloriesTarget) {
      _maybeRaiseCalorieAlert(
        ref,
        userId: user.id,
        calories: totals.calories,
        target: caloriesTarget,
      );
    }

    // Keep the daily meal-log reminders in sync with what's been logged today:
    // skip a slot's reminder for today once that meal is recorded. Runs whenever
    // the patient opens the dashboard; scheduling is idempotent.
    if (user != null) {
      final loggedMealTypes = todayEntries
          .map((e) => e.mealType)
          .whereType<String>()
          .toSet();
      _syncMealReminders(ref, loggedMealTypes);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TodayOverview(
              user: user,
              profile: profile,
              pregnancy: pregnancy,
              totals: totals,
              targets: targets,
              todayWater: todayWater,
              waterTarget: waterTarget,
              upcoming: upcoming,
              unreadAlerts: unreadAlerts,
              onOpenNotifications: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverList.list(
              children: [
                _QuickActions(onOpenTab: onOpenTab),
                const SizedBox(height: 16),
                _NutritionSummary(
                  totals: totals,
                  targets: targets,
                ),
                const SizedBox(height: 16),
                _AssessmentsBanner(onOpen: onOpenAssessments),
                const SizedBox(height: 16),
                _RecentMeals(
                  entries: todayEntries,
                  onOpenTab: onOpenTab,
                ),
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
}

double _ratio(num value, num target) {
  if (target <= 0) return 0;
  return (value / target).clamp(0.0, 1.0).toDouble();
}

/// Builds the dashboard header subtitle from only the segments that have real
/// data, so missing profile/pregnancy info doesn't surface raw placeholders
/// like "Week 0" or "BMI --". Falls back to a setup prompt when nothing is set.
String _headerSubtitle(int gestationalWeek, String? riskLabel, String bmi) {
  // [riskLabel] is the clinical tier already formatted as "… Risk"
  // (e.g. "Low Risk"); null when no risk level is set.
  final parts = <String>[
    if (gestationalWeek > 0) 'Week $gestationalWeek',
    if (riskLabel != null && riskLabel.isNotEmpty) riskLabel,
    if (bmi != '--' && bmi.isNotEmpty) 'BMI $bmi',
  ];
  if (parts.isEmpty) return 'Complete your pregnancy profile to personalise this';
  return parts.join(' • ');
}

/// Per-session guard so the calorie alert is written at most once per day per
/// patient even as the dashboard rebuilds. The Firestore doc id is also
/// deterministic (date-keyed), so repeats are idempotent regardless.
final Set<String> _raisedCalorieAlertKeys = <String>{};

void _maybeRaiseCalorieAlert(
  WidgetRef ref, {
  required String userId,
  required int calories,
  required int target,
}) {
  final now = DateTime.now();
  final dayKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final key = '${userId}_calorie-exceeded_$dayKey';
  if (_raisedCalorieAlertKeys.contains(key)) return;
  _raisedCalorieAlertKeys.add(key);

  final overBy = calories - target;
  final alert = AlertItem(
    id: key,
    userId: userId,
    message: "You've exceeded your daily calorie target by $overBy kcal "
        '($calories / $target kcal). Consider lighter meals for the rest of '
        'the day.',
    severity: AlertSeverity.medium,
    type: AlertType.deficiencyAlert,
    createdAt: now,
    status: 'SENT',
  );
  // Fire-and-forget; failures shouldn't disrupt the dashboard. A re-write with
  // the same id just refreshes the existing alert.
  ref.read(alertRepositoryProvider).addAlert(alert).catchError((_) {});
}

/// Guards meal-reminder reconciliation so it runs only when today's set of
/// logged meal slots actually changes (not on every dashboard rebuild).
String? _lastMealReminderSyncKey;

/// (Re)schedules the daily meal-log reminders, suppressing today's reminder for
/// any meal slot already logged. Fire-and-forget; the scheduler is mobile-only
/// and a no-op on web.
void _syncMealReminders(WidgetRef ref, Set<String> loggedMealTypesToday) {
  final now = DateTime.now();
  final dayKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final sorted = loggedMealTypesToday.toList()..sort();
  final key = '${dayKey}_${sorted.join(',')}';
  if (_lastMealReminderSyncKey == key) return;
  _lastMealReminderSyncKey = key;

  ref
      .read(mealReminderServiceProvider)
      .reconcileForToday(loggedMealTypesToday)
      .catchError((_) {});
}

class _TodayOverview extends StatelessWidget {
  const _TodayOverview({
    required this.user,
    required this.profile,
    required this.pregnancy,
    required this.totals,
    required this.targets,
    required this.todayWater,
    required this.waterTarget,
    required this.upcoming,
    required this.unreadAlerts,
    required this.onOpenNotifications,
  });

  final AppUser? user;
  final Profile? profile;
  final Pregnancy? pregnancy;
  final _DailyTotals totals;
  final RecommendedTargets targets;
  final int todayWater;
  final int waterTarget;
  final List<Appointment> upcoming;
  final int unreadAlerts;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final gestationalWeek = pregnancy?.gestationalWeek ?? 0;
    // Risk level is stored as an MOH colour code (e.g. 'green'); show its
    // clinical tier (No / Low / High / Extremely High Risk), not the colour.
    final riskLabel = PregnancyRiskLevel.fromCode(pregnancy?.riskLevel)?.riskLabel;
    final bmi = profile?.bmi.toStringAsFixed(1) ?? '--';
    final caloriesTarget = targets.calories.round();
    final caloriesProgress = _ratio(totals.calories, targets.calories);

    final scheme = Theme.of(context).colorScheme;
    final onHeader = scheme.onPrimaryContainer;

    return Container(
      // Distinct header banner — pink-palette gradient that differs from the
      // page background but stays within the MD3 scheme (adapts to dark mode).
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.18),
              scheme.primaryContainer,
            ),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user?.displayName ?? user?.email ?? 'Mother'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: onHeader,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _headerSubtitle(gestationalWeek, riskLabel, bmi),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onHeader.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(width: 8),
              // Settings moved to the Profile tab only; the header keeps the
              // notification bell.
              _NotificationBell(
                unread: unreadAlerts,
                onTap: onOpenNotifications,
                onHeader: onHeader,
                surface: scheme.surface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  title: 'Today Calories Target',
                  value: '$caloriesTarget kcal',
                  progress: caloriesProgress,
                  color: AppTheme.darkPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewMetric(
                  title: 'Today Water Target',
                  value: '${(waterTarget / 1000).toStringAsFixed(1)}L',
                  progress: _ratio(todayWater, waterTarget),
                  color: AppTheme.healthcareTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Header notification bell with an unread-count badge.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unread,
    required this.onTap,
    required this.onHeader,
    required this.surface,
  });

  final int unread;
  final VoidCallback onTap;
  final Color onHeader;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          tooltip: 'Notifications',
          onPressed: onTap,
          icon: Icon(
            unread > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
          ),
          style: IconButton.styleFrom(
            backgroundColor: surface.withValues(alpha: 0.6),
            foregroundColor: onHeader,
            minimumSize: const Size(48, 48),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String title;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.6), scheme.onSurface)
        : color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withValues(alpha: 0.039),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.center_focus_strong,
                label: 'Scan Food',
                color: AppTheme.darkPink,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FoodScanScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.restaurant_menu,
                label: 'Log Meal',
                color: AppTheme.info,
                onTap: () => onOpenTab(1), // Log tab
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.water_drop_outlined,
                label: 'Log Water',
                color: AppTheme.healthcareTeal,
                onTap: () => onOpenTab(1), // Log tab (hydration lives here)
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.7), scheme.onSurface)
        : color;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.28 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentsBanner extends StatelessWidget {
  const _AssessmentsBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Digital Assessments',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.blushGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryPink.withValues(alpha: 0.196)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.darkPink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Assessments',
                        // Banner uses a fixed light-pink gradient in both
                        // themes, so pin the text to dark for legibility.
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryText,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Check gestational diabetes, nutrition & more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF59677D),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.darkPink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({
    required this.totals,
    required this.targets,
  });

  final _DailyTotals totals;
  final RecommendedTargets targets;

  @override
  Widget build(BuildContext context) {
    final caloriesTarget = targets.calories.round();
    final proteinTarget = targets.protein;
    final carbsTarget = (targets.calories * targets.carbPct / 4).round();
    final fatTarget = (targets.calories * targets.fatPct / 9).round();

    // Over-target detection: warn once today's intake passes the daily target.
    final caloriesOver = caloriesTarget > 0 && totals.calories > caloriesTarget;
    final caloriesOverBy = totals.calories - caloriesTarget;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caloriesOver) ...[
            const SizedBox(height: 12),
            _CalorieWarningBanner(overBy: caloriesOverBy),
          ],
          const SizedBox(height: 16),
          // Macro split as a donut: Protein / Carbs / Fat by their calorie
          // contribution (P×4, C×4, F×9), with today's total calories shown in
          // the centre. The chips below act as an exact-value legend.
          _MacroDonut(
            totals: totals,
            caloriesTarget: caloriesTarget,
            caloriesOver: caloriesOver,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NutrientChip(
                  label: 'Calories',
                  value: '${totals.calories}',
                  target: '$caloriesTarget',
                  color: AppTheme.darkPink,
                  exceeded: caloriesOver,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientChip(
                  label: 'Protein',
                  value: '${totals.protein}g',
                  target: '$proteinTarget g',
                  color: AppTheme.healthcareTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientChip(
                  label: 'Carbs',
                  value: '${totals.carbs}g',
                  target: '$carbsTarget g',
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientChip(
                  label: 'Fat',
                  value: '${totals.fat}g',
                  target: '$fatTarget g',
                  color: AppTheme.primaryPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Donut pie chart of the macro split (Protein / Carbs / Fat by calorie
/// contribution) with today's total calories in the centre. Renders an empty
/// neutral ring with a "No meals logged yet" hint when nothing is logged.
class _MacroDonut extends StatelessWidget {
  const _MacroDonut({
    required this.totals,
    required this.caloriesTarget,
    required this.caloriesOver,
  });

  final _DailyTotals totals;
  final int caloriesTarget;
  final bool caloriesOver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Macro energy contributions (kcal). Protein & carbs are 4 kcal/g, fat 9.
    final proteinKcal = (totals.protein * 4).toDouble();
    final carbsKcal = (totals.carbs * 4).toDouble();
    final fatKcal = (totals.fat * 9).toDouble();
    final macroKcal = proteinKcal + carbsKcal + fatKcal;
    final empty = macroKcal <= 0;

    final slices = <_MacroSlice>[
      _MacroSlice('Protein', proteinKcal, AppTheme.healthcareTeal),
      _MacroSlice('Carbs', carbsKcal, AppTheme.info),
      _MacroSlice('Fat', fatKcal, AppTheme.primaryPink),
    ];
    final caloriesColor = caloriesOver
        ? (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.errorDark
            : AppTheme.errorColor)
        : scheme.onSurface;

    // Screen-reader summary for the otherwise purely-visual donut.
    final semanticsLabel = empty
        ? 'No meals logged yet. ${totals.calories} of $caloriesTarget kcal.'
        : '${totals.calories} of $caloriesTarget kilocalories. '
            'Protein ${totals.protein} grams, carbs ${totals.carbs} grams, '
            'fat ${totals.fat} grams.';

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: empty ? 0 : 2,
              centerSpaceRadius: 52,
              startDegreeOffset: -90,
              sections: empty
                  ? [
                      PieChartSectionData(
                        value: 1,
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        radius: 26,
                        showTitle: false,
                      ),
                    ]
                  : [
                      for (final s in slices)
                        if (s.value > 0)
                          PieChartSectionData(
                            value: s.value,
                            color: s.color,
                            radius: 26,
                            title:
                                '${(s.value / macroKcal * 100).round()}%',
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                    ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${totals.calories}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: caloriesColor,
                    ),
              ),
              Text(
                empty ? 'No meals yet' : '/ $caloriesTarget kcal',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _MacroSlice {
  const _MacroSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.exceeded = false,
  });

  final String label;
  final String value;
  final String target;
  final Color color;

  /// When true the intake has passed the target — the chip is recoloured to a
  /// warning tone to draw attention.
  final bool exceeded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // When over target, the chip turns RED to flag it. Use a brighter red in
    // dark mode for legibility.
    final baseTone = exceeded
        ? (isDark ? AppTheme.errorDark : AppTheme.errorColor)
        : color;
    final tone = isDark
        ? Color.alphaBlend(baseTone.withValues(alpha: 0.55), scheme.onSurface)
        : baseTone;
    // The value text is red when exceeded, otherwise the normal surface text.
    final valueColor = exceeded ? tone : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseTone.withValues(alpha: isDark ? 0.20 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseTone.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Legend dot — links this chip to its slice in the macro donut.
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: baseTone,
                  shape: BoxShape.circle,
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: exceeded
                        ? tone
                        : scheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (exceeded) ...[
                const SizedBox(width: 3),
                Icon(Icons.warning_amber_rounded, size: 13, color: tone),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              Text(
                target,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning banner shown on the Nutrition Summary when today's calorie intake
/// exceeds the recommended daily target.
class _CalorieWarningBanner extends StatelessWidget {
  const _CalorieWarningBanner({required this.overBy});

  /// How many kcal over the target the user is (always > 0 when shown).
  final int overBy;

  @override
  Widget build(BuildContext context) {
    // "Exceeded" is a warning the user must notice → solid red banner with
    // white text, legible in both light and dark themes.
    const fill = AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calorie target exceeded',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You're $overBy kcal over your daily target. Consider "
                  'lighter meals or a short walk, and check with your '
                  'dietitian if this is frequent.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMeals extends StatelessWidget {
  const _RecentMeals({
    required this.entries,
    required this.onOpenTab,
  });

  final List<FoodEntry> entries;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final todayEntries = entries.where((entry) => _isToday(entry.date)).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Meals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => onOpenTab(1), // Log tab
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.darkPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          todayEntries.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 32,
                        color: AppTheme.darkPink.withValues(alpha: 0.118),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No meals logged today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap Log to add your first meal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = todayEntries[index];
                    return _MealItem(
                      meal: entry.meal,
                      calories: entry.calories,
                      time: _formatTime(entry.date),
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.meal,
    required this.calories,
    required this.time,
  });

  final String meal;
  final int calories;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.darkPink.withValues(alpha: 0.039),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkPink,
              ),
            ),
          ),
        ],
      ),
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
