import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/nutrition_guideline.dart';
import 'package:smartbunda/services/nutrition_guideline_repository.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';

/// Admin screen to upload/manage nutrition guidelines and activate a version.
///
/// The AI food-recommendation engine reads whichever guideline is **active**
/// as its highest-priority source; if none is active it uses the built-in
/// MOH maternal default.
class NutritionGuidelineAdminScreen extends ConsumerWidget {
  const NutritionGuidelineAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidelinesAsync =
        ref.watch(_guidelinesStreamProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Guidelines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('New guideline'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.m, AppSpacing.m, AppSpacing.m, 96),
        children: [
          Text(
            'The active guideline is the highest-priority source for AI food '
            'recommendations. If none is active, the built-in MOH maternal '
            'default is used.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.m),
          // Built-in default (read-only reference).
          SbCard(
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.s + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Built-in MOH maternal default',
                          style: text.titleSmall),
                      Text(NutritionGuideline.maternalDefault.version,
                          style: text.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SbStatusPill(label: 'Fallback', status: SbStatus.info),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          guidelinesAsync.when(
            data: (list) => list.isEmpty
                ? Text('No custom guidelines uploaded yet.',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant))
                : Column(
                    children: [
                      for (final g in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s),
                          child: _GuidelineCard(stored: g),
                        ),
                    ],
                  ),
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _GuidelineEditor(),
    );
  }
}

final _guidelinesStreamProvider =
    StreamProvider<List<StoredGuideline>>((ref) {
  return ref.watch(nutritionGuidelineRepositoryProvider).watchAll();
});

class _GuidelineCard extends ConsumerWidget {
  const _GuidelineCard({required this.stored});
  final StoredGuideline stored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final g = stored.guideline;
    final repo = ref.read(nutritionGuidelineRepositoryProvider);
    return SbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.title, style: text.titleMedium)),
              if (stored.isActive)
                const SbStatusPill(label: 'Active', status: SbStatus.success)
              else
                const SbStatusPill(label: 'Inactive', status: SbStatus.neutral),
            ],
          ),
          const SizedBox(height: 2),
          Text('${g.source} · v${g.version}',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          if (stored.updatedAt != null)
            Text('Updated ${DateFormat('d MMM yyyy').format(stored.updatedAt!)}',
                style:
                    text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.s),
          if (g.prohibitedFoods.isNotEmpty)
            Text('Excludes: ${g.prohibitedFoods.take(6).join(', ')}…',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              if (stored.isActive)
                OutlinedButton.icon(
                  onPressed: () => repo.deactivate(stored.docId),
                  icon: const Icon(Icons.pause_circle_outline, size: 18),
                  label: const Text('Deactivate'),
                )
              else
                FilledButton.icon(
                  onPressed: () => repo.setActive(stored.docId),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Activate'),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, repo, stored.docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      NutritionGuidelineRepository repo, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete guideline?'),
        content: const Text('This guideline version will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await repo.delete(docId);
  }
}

class _GuidelineEditor extends ConsumerStatefulWidget {
  const _GuidelineEditor();

  @override
  ConsumerState<_GuidelineEditor> createState() => _GuidelineEditorState();
}

class _GuidelineEditorState extends ConsumerState<_GuidelineEditor> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Maternal Nutrition Guideline');
  final _source = TextEditingController();
  final _version = TextEditingController();
  final _prohibited = TextEditingController(
      text: NutritionGuideline.maternalDefault.prohibitedFoods.join(', '));
  final _mealRules = TextEditingController(
      text: NutritionGuideline.maternalDefault.mealRules.join('\n'));
  final _protein = TextEditingController(text: '71');
  final _iron = TextEditingController(text: '30');
  final _calcium = TextEditingController(text: '1000');
  final _folate = TextEditingController(text: '600');
  final _sodiumCap = TextEditingController(text: '800');
  final _sugarCap = TextEditingController(text: '25');
  bool _activateNow = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _title, _source, _version, _prohibited, _mealRules,
      _protein, _iron, _calcium, _folate, _sodiumCap, _sugarCap,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final guideline = NutritionGuideline(
        version: _version.text.trim(),
        source: _source.text.trim(),
        title: _title.text.trim(),
        nutrientTargets: {
          'protein': num.tryParse(_protein.text) ?? 71,
          'iron': num.tryParse(_iron.text) ?? 30,
          'calcium': num.tryParse(_calcium.text) ?? 1000,
          'folate': num.tryParse(_folate.text) ?? 600,
        },
        prohibitedFoods: _splitList(_prohibited.text),
        prohibitedCategories: const ['alcohol'],
        mealRules: _mealRules.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        maxSodiumMgPerMeal: num.tryParse(_sodiumCap.text),
        maxSugarGPerMeal: num.tryParse(_sugarCap.text),
      );
      await ref
          .read(nutritionGuidelineRepositoryProvider)
          .upsert(guideline, activate: _activateNow);
      messenger.showSnackBar(
        const SnackBar(content: Text('Guideline saved.')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _splitList(String raw) => raw
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New nutrition guideline',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _source,
                decoration: const InputDecoration(
                    labelText: 'Source (e.g. MOH Malaysia 2024)'),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _version,
                decoration: const InputDecoration(
                    labelText: 'Version id (e.g. moh-my-2024.1)'),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.m),
              Text('Daily nutrient targets',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s),
              Row(children: [
                Expanded(child: _numField(_protein, 'Protein (g)')),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: _numField(_iron, 'Iron (mg)')),
              ]),
              const SizedBox(height: AppSpacing.s),
              Row(children: [
                Expanded(child: _numField(_calcium, 'Calcium (mg)')),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: _numField(_folate, 'Folate (mcg)')),
              ]),
              const SizedBox(height: AppSpacing.s),
              Row(children: [
                Expanded(child: _numField(_sodiumCap, 'Sodium cap (mg/meal)')),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: _numField(_sugarCap, 'Sugar cap (g/meal)')),
              ]),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _prohibited,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Prohibited foods (comma-separated)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _mealRules,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Meal rules (one per line)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activate immediately'),
                subtitle:
                    const Text('Deactivates any other active guideline.'),
                value: _activateNow,
                onChanged: (v) => setState(() => _activateNow = v),
              ),
              const SizedBox(height: AppSpacing.s),
              SbLoadingButton(
                label: 'Save Guideline',
                icon: Icons.save_outlined,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      );

  String? _required(String? v) =>
      (v != null && v.trim().isNotEmpty) ? null : 'Required';
}
