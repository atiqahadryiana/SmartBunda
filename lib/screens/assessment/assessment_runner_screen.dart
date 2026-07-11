import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/assessment_catalog.dart';
import 'package:smartbunda/models/assessment_result.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/screens/assessment/assessment_result_screen.dart';
import 'package:smartbunda/theme/app_spacing.dart';
import 'package:smartbunda/theme/app_theme.dart';

/// Runs a single [Assessment]: instructions → one question per page →
/// computes a result and pushes the result screen (where Save is mandatory).
///
/// For the Gestational Diabetes Risk assessment, the age-group and
/// pre-pregnancy body-size questions are pre-filled from the patient's profile
/// (age derived from date of birth; body size from BMI) so they don't have to
/// re-enter known data — they can still change the selection.
class AssessmentRunnerScreen extends ConsumerStatefulWidget {
  const AssessmentRunnerScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  ConsumerState<AssessmentRunnerScreen> createState() =>
      _AssessmentRunnerScreenState();
}

class _AssessmentRunnerScreenState
    extends ConsumerState<AssessmentRunnerScreen> {
  /// questionId → selected option index.
  final Map<String, int> _answers = {};

  /// questionId set whose answer was auto-derived from the profile (shown as a
  /// hint, and so we don't overwrite a value the user has since changed).
  final Set<String> _autoFilled = {};

  /// -1 = instructions page; 0..n-1 = questions.
  int _page = -1;

  Assessment get _a => widget.assessment;
  int get _count => _a.questions.length;

  @override
  void initState() {
    super.initState();
    if (_a.id == 'gdm_risk') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
    }
  }

  /// Pre-selects the GDM age-group (from DOB) and body-size (from BMI) answers
  /// from the current patient's profile. No-op when the data is missing.
  void _prefillFromProfile() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    final updates = <String, int>{};

    final age = profile.age;
    if (age != null && age > 0) {
      // Options: Under 25 (0) · 25–34 (1) · 35 or older (2).
      updates['age'] = age < 25
          ? 0
          : age <= 34
              ? 1
              : 2;
    }

    if (updates.isEmpty || !mounted) return;
    setState(() {
      for (final entry in updates.entries) {
        // Don't clobber anything the user already answered themselves.
        if (!_answers.containsKey(entry.key)) {
          _answers[entry.key] = entry.value;
          _autoFilled.add(entry.key);
        }
      }
    });
  }

  void _start() => setState(() => _page = 0);

  void _back() {
    if (_page <= -1) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _page--);
    }
  }

  void _next() {
    if (_page < _count - 1) {
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _finish() {
    var score = 0;
    final answerLabels = <String, String>{};
    for (final q in _a.questions) {
      final idx = _answers[q.id];
      if (idx == null) continue;
      score += q.options[idx].points;
      answerLabels[q.id] = q.options[idx].label;
    }
    final rule = _a.bandFor(score);
    final completedAt = DateTime.now();
    final result = AssessmentResult(
      // Stable id: assessment + timestamp. Used as the Firestore doc id so a
      // re-tap of Save is idempotent.
      id: '${_a.id}_${completedAt.microsecondsSinceEpoch}',
      patientId: '', // filled in on save by the result screen
      assessmentId: _a.id,
      assessmentTitle: _a.title,
      version: _a.version,
      score: score,
      maxScore: _a.maxScore,
      band: rule.band,
      summary: rule.summary,
      recommendations: rule.recommendations,
      answers: answerLabels,
      completedAt: completedAt,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(
          assessment: _a,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_a.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: _page == -1 ? _instructions() : _question(),
    );
  }

  // ── Instructions (step 2 of the flow) ─────────────────────────────────────
  Widget _instructions() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadius.brL,
                ),
                child: Icon(_a.icon,
                    size: 36, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(_a.title, style: text.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _a.subtitle,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Before you start', style: text.titleSmall),
              const SizedBox(height: AppSpacing.s),
              Text(
                _a.instructions,
                style: text.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.l),
              _disclaimer(context),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _start,
                child: const Text('Start Assessment'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Question page (step 3) ────────────────────────────────────────────────
  Widget _question() {
    final q = _a.questions[_page];
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final selected = _answers[q.id];
    final progress = (_page + 1) / _count;
    final isLast = _page == _count - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question ${_page + 1} of $_count',
                      style: text.labelLarge
                          ?.copyWith(color: scheme.primary)),
                  Text('${(progress * 100).round()}%',
                      style: text.labelLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              ClipRRect(
                borderRadius: AppRadius.brFull,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
            children: [
              Text(q.text, style: text.titleLarge),
              if (_autoFilled.contains(q.id)) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filled in from your profile — change it if needed.',
                        style: text.bodySmall?.copyWith(color: scheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              for (var i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: _OptionTile(
                    label: q.options[i].label,
                    selected: selected == i,
                    onTap: () => setState(() => _answers[q.id] = i),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s + 4),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    // Force an answer before advancing.
                    onPressed: selected == null ? null : _next,
                    child: Text(isLast ? 'View Result' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: AppRadius.brM,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brM,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brM,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? scheme.primary : scheme.outline,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.s + 4),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared medical disclaimer banner (matches the clinical-assessment screen).
Widget _disclaimer(BuildContext context) {
  final semantic = Theme.of(context).extension<SmartBundaColors>()!;
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(AppSpacing.m),
    decoration: BoxDecoration(
      color: semantic.warning.withValues(alpha: 0.12),
      borderRadius: AppRadius.brM,
      border: Border.all(color: semantic.warning.withValues(alpha: 0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: semantic.warning, size: 20),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: Text(
            'This is a screening questionnaire, not a medical diagnosis. '
            'Always consult a qualified healthcare professional for advice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ),
      ],
    ),
  );
}
