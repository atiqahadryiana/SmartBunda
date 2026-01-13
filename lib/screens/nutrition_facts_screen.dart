import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
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
    final strings = AppStrings.of(context);
    final pregnancy = ref.watch(pregnancyProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final targets = recommendedFor(pregnancy);

    final rows = [
      _RowData(strings.t('Calories'), '${targets.calories} kcal'),
      _RowData(strings.t('Protein'), '${targets.protein} g'),
      _RowData(strings.t('Water'), '${targets.waterMl} ml'),
      _RowData(strings.t('Iron'), '${targets.ironMg} mg'),
      _RowData(strings.t('Folate'), '${targets.folateMcg} mcg'),
    ];

    return RequireSignIn(
      title: strings.t('Nutrition facts'),
      showAppBar: true,
      message: strings.t('Please sign in to view nutrition facts.'),
      child: Scaffold(
        appBar: AppBar(title: Text(strings.t('Nutrition facts'))),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: strings.t('Nutrition facts'),
                subtitle: strings.basedOnTrimester(_conditionNote(profile, strings)),
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
              Text(
                strings.t(
                  'These are general targets for pregnancy. Consult your care team for personal guidance.',
                ),
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _conditionNote(Profile? profile, AppStrings strings) {
    if (profile == null || profile.medicalConditions.isEmpty) return '';
    final labels = profile.medicalConditions.map((c) {
      switch (c) {
        case MedicalCondition.gestationalDiabetes:
          return strings.t('GDM');
        case MedicalCondition.anemia:
          return strings.t('anemia');
      }
    }).join(', ');
    return strings.conditionsLabel(labels);
  }
}

class _RowData {
  _RowData(this.label, this.value);
  final String label;
  final String value;
}
