import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/firestore_doc.dart';
import '../providers/app_providers.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';
import 'module_overview_screen.dart';
import 'nutrition_facts_screen.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(educationContentProvider);
    return RequireSignIn(
      title: 'Education & content',
      showAppBar: true,
      message: 'Please sign in to view education content.',
      child: Scaffold(
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
            contentAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From database', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...items.map(
                      (doc) => _EducationCard(
                        icon: Icons.menu_book_outlined,
                        title: doc.title ?? doc.id,
                        subtitle: doc.subtitle ?? 'Tap to view details.',
                        onTap: () => _openDoc(context, doc),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Error loading content: $e'),
              ),
            ),
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
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openDoc(BuildContext context, FirestoreDoc doc) {
    final entries = doc.data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title ?? doc.id),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key}: ${_valueLabel(entry.value)}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _valueLabel(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Iterable) {
      return value.map((item) => item.toString()).join(', ');
    }
    return value.toString();
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
