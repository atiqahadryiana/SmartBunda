import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../widgets/screen_header.dart';
import 'food_scan_screen.dart';
import 'hydration_screen.dart';
import 'log_screen.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          ScreenHeader(
            title: strings.t('Food logging'),
            subtitle: strings
                .t('Log meals and hydration to keep recommendations accurate.'),
            icon: Icons.restaurant_menu,
          ),
          const SizedBox(height: 16),
          Text(
            strings.t('Choose how you want to log'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
            icon: Icons.water_drop_outlined,
            title: strings.t('Hydration log'),
            subtitle: strings.t('Track water intake and reminders.'),
            onTap: () => _open(context, const HydrationScreen()),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t(
                'Tip: scan when you have a clear food photo, or use manual entry when the dish is mixed.'),
            style: Theme.of(context).textTheme.bodySmall,
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
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
