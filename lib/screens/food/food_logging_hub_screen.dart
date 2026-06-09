import 'package:flutter/material.dart';
import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/screens/food/food_picker_modal.dart';
import 'package:smartbunda/screens/food/food_picker_confirm_screen.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/screens/food/food_scan_screen.dart';
import 'package:smartbunda/screens/food/food_history_screen.dart';
import 'package:smartbunda/screens/food/hydration_screen.dart';
import 'package:smartbunda/screens/food/log_screen.dart';

class FoodLoggingHubScreen extends StatelessWidget {
  const FoodLoggingHubScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(strings.t('Food logging & nutrition')))
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 128),
        children: [
          _NutritionHero(
            title: strings.t('Food & Water Log'),
            subtitle: strings.t(
              'Track meals, hydration, AI scan results, and daily nutrition in one clean flow.',
            ),
          ),
          const SizedBox(height: 16),
          _SummaryStrip(strings: strings),
          const SizedBox(height: 18),
          _ModuleCard(
            icon: Icons.restaurant_menu,
            title: strings.t('Meal log'),
            subtitle:
                strings.t('Add meals manually or from the food database.'),
            onTap: () => _open(context, const LogScreen()),
          ),
          _ModuleCard(
            icon: Icons.center_focus_strong,
            title: strings.t('Meal scanner'),
            subtitle: strings.t(
              'Use your camera or gallery to detect a meal and save it faster.',
            ),
            onTap: () => _open(context, const FoodScanScreen()),
          ),
          _ModuleCard(
            icon: Icons.history,
            title: strings.t('Food History'),
            subtitle: strings.t(
              'Review past scans with confidence and quality scores.',
            ),
            onTap: () => _open(context, const FoodHistoryScreen()),
          ),
          _ModuleCard(
            icon: Icons.search_outlined,
            title: strings.t('Browse food database'),
            subtitle: strings.t(
              'Find and select meals from our curated Malaysian food database.',
            ),
            onTap: () async {
              final result = await showFoodPickerModal(context);
              if (result != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FoodPickerConfirmScreen(result: result),
                  ),
                );
              }
            },
          ),
          _ModuleCard(
            icon: Icons.water_drop_outlined,
            title: strings.t('Hydration log'),
            subtitle: strings.t('Track water intake and reminders.'),
            onTap: () => _open(context, const HydrationScreen()),
          ),
          const SizedBox(height: 8),
          _TipBanner(
            text: strings.t(
              'Scan clear food photos, or use manual entry when the dish is mixed.',
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _NutritionHero extends StatelessWidget {
  const _NutritionHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 50)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 220),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkPink.withValues(alpha: 20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.restaurant_menu, color: AppTheme.darkPink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF59677D),
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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniSummary(
            icon: Icons.local_fire_department_outlined,
            label: strings.t('Calories'),
            value: '0 kcal',
            color: AppTheme.darkPink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniSummary(
            icon: Icons.water_drop_outlined,
            label: strings.t('Water'),
            value: '0.0 L',
            color: AppTheme.healthcareTeal,
          ),
        ),
      ],
    );
  }
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: AppTheme.primaryPink.withValues(alpha: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF8BBD0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF5F8), Color(0xFFFCE4EC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.darkPink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF687386),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.blushGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: AppTheme.darkPink),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
