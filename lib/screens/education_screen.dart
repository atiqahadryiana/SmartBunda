import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
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
    final strings = AppStrings.of(context);
    return RequireSignIn(
      title: strings.t('Education & content'),
      showAppBar: true,
      message: strings.t('Please sign in to view education content.'),
      child: Scaffold(
        appBar: AppBar(title: Text(strings.t('Education & content'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ScreenHeader(
              title: strings.t('Education'),
              subtitle: strings.t('Browse guides, tips, and trimester content.'),
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
                    Text(strings.t('From database'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...items.map(
                      (doc) => _EducationCard(
                        icon: Icons.menu_book_outlined,
                        title: doc.title ?? doc.id,
                        subtitle: doc.subtitle ?? strings.t('Tap to view details.'),
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
                child: Text(strings.errorLoadingContent('$e')),
              ),
            ),
            _EducationCard(
              icon: Icons.menu_book_outlined,
              title: strings.t('Trimester nutrition guide'),
              subtitle: strings.t('Recommended targets based on gestation stage.'),
              onTap: () => _open(context, const NutritionFactsScreen()),
            ),
            _EducationCard(
              icon: Icons.restaurant_outlined,
              title: strings.t('Healthy meal suggestions'),
              subtitle: strings.t('Balanced meal ideas and snack tips.'),
              onTap: () => _open(
                context,
                ModuleOverviewScreen(
                  title: strings.t('Healthy meal suggestions'),
                  description: strings.t('Curated meal ideas for each trimester.'),
                  icon: Icons.restaurant_outlined,
                  features: [
                    strings.t('Iron-rich meals with leafy greens and lean proteins'),
                    strings.t('Calcium-forward snacks and dairy alternatives'),
                    strings.t('Balanced plates with complex carbs and fiber'),
                  ],
                  footer: strings.t('Personalize recommendations with your care team.'),
                ),
              ),
            ),
            _EducationCard(
              icon: Icons.lightbulb_outline,
              title: strings.t('Pregnancy nutrition FAQs'),
              subtitle: strings.t('Quick guidance and common questions.'),
              onTap: () => _open(
                context,
                ModuleOverviewScreen(
                  title: strings.t('Pregnancy nutrition FAQs'),
                  description: strings.t('Common questions answered in one place.'),
                  icon: Icons.lightbulb_outline,
                  features: [
                    strings.t('How much water should I drink daily?'),
                    strings.t('What foods support healthy iron levels?'),
                    strings.t('Safe caffeine limits during pregnancy'),
                  ],
                  footer: strings.t('Always consult your clinician for medical advice.'),
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
    final strings = AppStrings.of(context);
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
            child: Text(strings.t('Close')),
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
