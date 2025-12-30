import 'package:flutter/material.dart';

import '../widgets/screen_header.dart';
import 'module_overview_screen.dart';
import 'nutrition_facts_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education & content')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenHeader(
            title: 'Education',
            subtitle: 'Browse guides, tips, and trimester content.',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 16),
          _EducationCard(
            icon: Icons.menu_book_outlined,
            title: 'Trimester nutrition guide',
            subtitle: 'Recommended targets based on gestation stage.',
            onTap: () => _open(context, const NutritionFactsScreen()),
          ),
          _EducationCard(
            icon: Icons.restaurant_outlined,
            title: 'Healthy meal suggestions',
            subtitle: 'Balanced meal ideas and snack tips.',
            onTap: () => _open(
              context,
              const ModuleOverviewScreen(
                title: 'Healthy meal suggestions',
                description: 'Curated meal ideas for each trimester.',
                icon: Icons.restaurant_outlined,
                features: [
                  'Iron-rich meals with leafy greens and lean proteins',
                  'Calcium-forward snacks and dairy alternatives',
                  'Balanced plates with complex carbs and fiber',
                ],
                footer: 'Personalize recommendations with your care team.',
              ),
            ),
          ),
          _EducationCard(
            icon: Icons.lightbulb_outline,
            title: 'Pregnancy nutrition FAQs',
            subtitle: 'Quick guidance and common questions.',
            onTap: () => _open(
              context,
              const ModuleOverviewScreen(
                title: 'Pregnancy nutrition FAQs',
                description: 'Common questions answered in one place.',
                icon: Icons.lightbulb_outline,
                features: [
                  'How much water should I drink daily?',
                  'What foods support healthy iron levels?',
                  'Safe caffeine limits during pregnancy',
                ],
                footer: 'Always consult your clinician for medical advice.',
              ),
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

class _EducationCard extends StatelessWidget {
  const _EducationCard({
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
