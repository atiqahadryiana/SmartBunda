import 'package:flutter/material.dart';
import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/screens/food/ai_food_recommendation_card.dart';
import 'package:smartbunda/screens/food/food_scan_screen.dart';
import 'package:smartbunda/screens/food/hydration_screen.dart';
import 'package:smartbunda/screens/food/log_screen.dart';

class FoodLoggingHubScreen extends StatelessWidget {
  const FoodLoggingHubScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.t('Log'))) : null,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SbHeaderBanner(
            title: strings.t('Log'),
            subtitle: strings.t(
              'Scan food, log meals, and track hydration in one place.',
            ),
            icon: Icons.restaurant_menu,
            safeAreaTop: !showAppBar,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
          // AI Food Recommendation — top of the Log Meal module (spec).
          const AiFoodRecommendationCard(),
          const SizedBox(height: 18),
          // (Calories/Water summary lives on Home only.)
          _ModuleCard(
            icon: Icons.center_focus_strong,
            title: strings.t('Scan food'),
            subtitle: strings.t(
              'Use your camera or gallery to detect a meal and save it faster.',
            ),
            onTap: () => _open(context, const FoodScanScreen()),
          ),
          _ModuleCard(
            icon: Icons.restaurant_menu,
            title: strings.t('Log meal'),
            subtitle: strings
                .t('Add meals from the food database or meal scanner.'),
            onTap: () => _open(context, const LogScreen()),
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
          const SizedBox(height: 128),
              ],
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
          splashColor: AppTheme.primaryPink.withValues(alpha: 0.078),
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
                              // Card is always white → pin title to dark text.
                              color: AppTheme.primaryText,
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
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.196)),
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
