import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/app_strings.dart';
import '../widgets/screen_header.dart';
import 'log/meal_log_actions.dart';

class FoodScanScreen extends ConsumerWidget {
  const FoodScanScreen({super.key});

  static const routeName = '/food-scan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Meal scanner'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScreenHeader(
            title: strings.t('Meal scanner'),
            subtitle: strings.t(
              'Use your camera or gallery to detect a Malaysian dish and add it to your meal log.',
            ),
            icon: Icons.center_focus_strong,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 28),
                  scheme.secondary.withValues(alpha: 18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.center_focus_strong, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.t('Scan and save meals faster'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.t(
                    'Smartbunda analyzes the image with TensorFlow Lite, matches the result to your food database, then lets you confirm the detected meal before saving.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => MealLogActions.captureMeal(
                      context,
                      ref,
                      source: ImageSource.camera,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(strings.t('Scan with camera')),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => MealLogActions.captureMeal(
                      context,
                      ref,
                      source: ImageSource.gallery,
                    ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(strings.t('Upload image')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('How it works'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _StepRow(
                    number: '1',
                    text: strings
                        .t('Take a photo or choose one from your gallery.'),
                  ),
                  const SizedBox(height: 10),
                  _StepRow(
                    number: '2',
                    text: strings.t(
                        'Review the detected food suggestions and pick the best match.'),
                  ),
                  const SizedBox(height: 10),
                  _StepRow(
                    number: '3',
                    text: strings.t(
                        'Confirm meal time and quantity, then save the log entry.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: Text(strings.t('TensorFlow Lite scanner')),
              subtitle: Text(
                strings.t(
                  'Use a bright, clear image with one main dish for better suggestions.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 22),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
