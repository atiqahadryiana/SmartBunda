import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class NutritionFactsScreen extends ConsumerWidget {
  const NutritionFactsScreen({super.key});
  static const routeName = '/nutrition-facts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(pregnancyProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final targets = recommendedFor(pregnancy);

    final rows = [
      _RowData('Calories', '${targets.calories} kcal'),
      _RowData('Protein', '${targets.protein} g'),
      _RowData('Water', '${targets.waterMl} ml'),
      _RowData('Iron', '${targets.ironMg} mg'),
      _RowData('Folate', '${targets.folateMcg} mcg'),
    ];

    return RequireSignIn(
      title: 'Nutrition facts',
      showAppBar: true,
      message: 'Please sign in to view nutrition facts.',
      child: Scaffold(
        appBar: AppBar(title: const Text('Nutrition facts')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Nutrition facts',
                subtitle: 'Based on your trimester${_conditionNote(profile)}.',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: rows
                      .map((r) => ListTile(
                            title: Text(r.label),
                            trailing: Text(r.value),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'These are general targets for pregnancy. Consult your care team for personal guidance.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _conditionNote(Profile? profile) {
    if (profile == null || profile.medicalConditions.isEmpty) return '';
    final labels = profile.medicalConditions.map((c) {
      switch (c) {
        case MedicalCondition.gestationalDiabetes:
          return 'GDM';
        case MedicalCondition.anemia:
          return 'anemia';
      }
    }).join(', ');
    return ' (conditions: $labels)';
  }
}

class _RowData {
  _RowData(this.label, this.value);
  final String label;
  final String value;
}
