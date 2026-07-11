import 'package:flutter/material.dart';

import 'package:smartbunda/models/assessment_catalog.dart';
import 'package:smartbunda/screens/assessment/assessment_runner_screen.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';

/// Digital Assessment hub — step 1 of the flow: select an assessment.
///
/// Lists every [AssessmentCatalog] entry as a tappable card. Tapping opens the
/// runner (instructions → questions → result with mandatory Save).
class AssessmentListScreen extends StatelessWidget {
  const AssessmentListScreen({super.key});

  static const routeName = '/assessments';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Assessments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.m, AppSpacing.s, AppSpacing.m, AppSpacing.xl),
        children: [
          Text(
            'Quick health screenings',
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete a short questionnaire to check your maternal health. '
            'Results are saved to your medical records.',
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          for (final assessment in AssessmentCatalog.all) ...[
            _AssessmentCard(assessment: assessment),
            const SizedBox(height: AppSpacing.s + 4),
          ],
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SbCard(
      semanticLabel: '${assessment.title}. ${assessment.subtitle}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssessmentRunnerScreen(assessment: assessment),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.brM,
            ),
            child: Icon(assessment.icon,
                color: scheme.onPrimaryContainer, size: 26),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assessment.title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  assessment.subtitle,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${assessment.questions.length} questions · ~2 min',
                  style: text.labelSmall?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.outline),
        ],
      ),
    );
  }
}
