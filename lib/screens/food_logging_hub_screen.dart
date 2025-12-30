import 'package:flutter/material.dart';

import '../widgets/screen_header.dart';
import 'hydration_screen.dart';
import 'log_screen.dart';
import 'summary_screen.dart';

class FoodLoggingHubScreen extends StatelessWidget {
  const FoodLoggingHubScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          showAppBar ? AppBar(title: const Text('Food logging & nutrition')) : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenHeader(
            title: 'Food logging',
            subtitle: 'Log meals and hydration to keep recommendations accurate.',
            icon: Icons.restaurant_menu,
          ),
          const SizedBox(height: 16),
          _ModuleCard(
            icon: Icons.restaurant_menu,
            title: 'Meal log',
            subtitle: 'Log daily food and beverage intake.',
            onTap: () => _open(context, const LogScreen()),
          ),
          _ModuleCard(
            icon: Icons.water_drop_outlined,
            title: 'Hydration log',
            subtitle: 'Track water intake and reminders.',
            onTap: () => _open(context, const HydrationScreen()),
          ),
          _ModuleCard(
            icon: Icons.assessment_outlined,
            title: 'Nutrition summary',
            subtitle: 'Review daily and weekly nutrition totals.',
            onTap: () => _open(context, const SummaryScreen(showAppBar: true)),
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
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
