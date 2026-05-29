import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/clinical_explanation_service.dart';
import '../theme/app_theme.dart';
import '../utils/clinical_rules.dart';

class PrePregnancyAssessmentScreen extends ConsumerStatefulWidget {
  const PrePregnancyAssessmentScreen({super.key});

  @override
  ConsumerState<PrePregnancyAssessmentScreen> createState() =>
      _PrePregnancyAssessmentScreenState();
}

class _PrePregnancyAssessmentScreenState
    extends ConsumerState<PrePregnancyAssessmentScreen> {
  final _ageController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _medicationController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _reproductiveHistoryController = TextEditingController();

  bool _intendsPregnancy = true;
  bool _diabetes = false;
  bool _hypertension = false;
  bool _heartDisease = false;
  bool _thyroid = false;
  bool _epilepsy = false;
  bool _asthma = false;
  bool _renal = false;
  bool _bloodDisorder = false;
  bool _mentalHealth = false;
  bool _infectiousRisk = false;
  bool _smoking = false;
  bool _alcohol = false;
  bool _substance = false;
  bool _psychosocialRisk = false;

  @override
  void dispose() {
    _ageController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _medicationController.dispose();
    _familyHistoryController.dispose();
    _reproductiveHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final result = _assessment(profile);
    final clinicalAssessment = _runClinicalEngine(profile);
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-pregnancy Assessment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Hero(result: result),
          const SizedBox(height: 16),
          _WorkflowCard(activeIndex: result.workflowIndex),
          const SizedBox(height: 16),
          _AssessmentForm(
            profile: profile,
            ageController: _ageController,
            systolicController: _systolicController,
            diastolicController: _diastolicController,
            medicationController: _medicationController,
            familyHistoryController: _familyHistoryController,
            reproductiveHistoryController: _reproductiveHistoryController,
            intendsPregnancy: _intendsPregnancy,
            onPregnancyIntent: (value) =>
                setState(() => _intendsPregnancy = value),
            onChanged: () => setState(() {}),
            flags: [
              _FlagState('Diabetes mellitus', _diabetes,
                  (value) => setState(() => _diabetes = value)),
              _FlagState('Hypertension', _hypertension,
                  (value) => setState(() => _hypertension = value)),
              _FlagState('Heart disease', _heartDisease,
                  (value) => setState(() => _heartDisease = value)),
              _FlagState('Thyroid disease', _thyroid,
                  (value) => setState(() => _thyroid = value)),
              _FlagState('Epilepsy', _epilepsy,
                  (value) => setState(() => _epilepsy = value)),
              _FlagState('Bronchial asthma', _asthma,
                  (value) => setState(() => _asthma = value)),
              _FlagState('Renal disorder', _renal,
                  (value) => setState(() => _renal = value)),
              _FlagState('Blood disorder', _bloodDisorder,
                  (value) => setState(() => _bloodDisorder = value)),
              _FlagState('Mental health condition', _mentalHealth,
                  (value) => setState(() => _mentalHealth = value)),
              _FlagState('Infectious disease risk', _infectiousRisk,
                  (value) => setState(() => _infectiousRisk = value)),
              _FlagState('Smoking', _smoking,
                  (value) => setState(() => _smoking = value)),
              _FlagState('Alcohol use', _alcohol,
                  (value) => setState(() => _alcohol = value)),
              _FlagState('Substance use', _substance,
                  (value) => setState(() => _substance = value)),
              _FlagState('Psychosocial risk', _psychosocialRisk,
                  (value) => setState(() => _psychosocialRisk = value)),
            ],
          ),
          const SizedBox(height: 16),
          _ResultCard(result: result),
          const SizedBox(height: 16),
          _ClinicalOutputPanel(assessment: clinicalAssessment),
          const SizedBox(height: 16),
          _CarePlanCard(result: result),
        ],
      ),
    );
  }

  _AssessmentResult _assessment(Profile? profile) {
    final risks = <String>[];
    final recommendations = <String>[];
    final referrals = <String>[];
    var score = 0;

    final age = int.tryParse(_ageController.text.trim());
    if (age != null && (age < 18 || age > 40)) {
      score += 2;
      risks.add(age < 18 ? 'Teenage pregnancy risk' : 'Advanced maternal age');
      referrals.add('Medical officer review for pregnancy suitability');
    }

    final bmi = profile?.bmi;
    if (bmi != null) {
      if (bmi >= 30) {
        score += 2;
        risks.add('Obese (BMI ≥ 30)');
        recommendations.add(
            'Weight optimisation required before pregnancy to reduce maternal and fetal risks.');
        referrals.add('Dietitian counselling');
      } else if (bmi >= 25.0) {
        score += 1;
        risks.add('Overweight (BMI 25.0–29.9)');
        recommendations
            .add('Target healthy BMI through diet and activity before conception.');
        referrals.add('Dietitian counselling');
      } else if (bmi < 18.5) {
        score += 1;
        risks.add('Underweight (BMI < 18.5)');
        recommendations.add('Improve nutritional status before conception.');
      }
    }

    final hb = profile?.hemoglobinGdl;
    if (hb != null && hb < 12.0) {
      score += 2;
      risks.add('Low haemoglobin (${hb.toStringAsFixed(1)} g/dL < 12.0)');
      recommendations.add(
          'Consult doctor for haematological assessment and optimisation before conception.');
      referrals.add('Medical officer review for anaemia management');
    }

    final systolic = int.tryParse(_systolicController.text.trim());
    final diastolic = int.tryParse(_diastolicController.text.trim());
    if (_hypertension ||
        (systolic != null && systolic >= 140) ||
        (diastolic != null && diastolic >= 90)) {
      score += 2;
      risks.add('Hypertension or raised blood pressure');
      referrals.add('Doctor review for BP control and medication safety');
    }

    final chronicFlags = {
      'Diabetes mellitus': _diabetes,
      'Heart disease': _heartDisease,
      'Thyroid disease': _thyroid,
      'Epilepsy': _epilepsy,
      'Bronchial asthma': _asthma,
      'Renal disorder': _renal,
      'Blood disorder': _bloodDisorder,
      'Mental health condition': _mentalHealth,
      'Infectious disease risk': _infectiousRisk,
    };
    for (final item in chronicFlags.entries) {
      if (!item.value) continue;
      score += item.key == 'Heart disease' || item.key == 'Renal disorder'
          ? 3
          : 2;
      risks.add(item.key);
      referrals.add('${item.key} shared-care review');
    }

    if (_smoking || _alcohol || _substance) {
      score += _substance ? 3 : 2;
      risks.add('Lifestyle exposure risk');
      recommendations.add('Start cessation support and avoid unsafe exposure.');
      referrals.add('Counselling support');
    }

    if (_psychosocialRisk) {
      score += 2;
      risks.add('Psychosocial risk');
      referrals.add('Psychosocial support and safety assessment');
    }

    if (_medicationController.text.trim().isNotEmpty) {
      score += 1;
      risks.add('Medication review needed');
      recommendations.add('Review medication safety before conception.');
    }
    if (_familyHistoryController.text.trim().isNotEmpty) {
      score += 1;
      risks.add('Family/genetic history noted');
      recommendations.add('Discuss genetic or family-history risk with staff.');
    }
    if (_reproductiveHistoryController.text.trim().isNotEmpty) {
      score += 1;
      risks.add('Reproductive history noted');
      recommendations.add('Review previous pregnancy outcomes and plans.');
    }

    if (!_intendsPregnancy) {
      recommendations.add(
          'Discuss family planning until health conditions are optimised.');
    } else {
      final highRiskNtd = _diabetes || _epilepsy;
      if (highRiskNtd) {
        recommendations.add(
            'High-risk NTD: Start folic acid 5 mg daily (diabetes or epilepsy present). Confirm dose with your doctor.');
      } else {
        recommendations.add(
            'Start folic acid 0.4 mg daily at least 3 months before conception to prevent neural tube defects.');
      }
      recommendations.add('Book pre-pregnancy follow-up and reassessment.');
    }
    recommendations.add('Maintain balanced diet, hydration, activity, and sleep.');

    final level = score >= 6
        ? _RiskLevel.high
        : score >= 3
            ? _RiskLevel.moderate
            : _RiskLevel.low;
    final readiness = !_intendsPregnancy
        ? 'Pregnancy deferred'
        : level == _RiskLevel.low
            ? 'Likely ready after routine review'
            : 'Optimise risks before pregnancy';

    return _AssessmentResult(
      level: level,
      score: score,
      readiness: readiness,
      risks: risks.isEmpty ? ['No major risk selected'] : risks,
      recommendations: recommendations.toSet().toList(),
      referrals: referrals.toSet().toList(),
      workflowIndex: level == _RiskLevel.low ? 6 : 3,
    );
  }

  /// Runs the SmartBunda Clinical Rule Engine from current form state.
  ClinicalAssessment _runClinicalEngine(Profile? profile) {
    return ClinicalRuleEngine.evaluate(
      ClinicalInput(
        context: ClinicalContext.prePregnancy,
        ageYears: int.tryParse(_ageController.text.trim()),
        bmi: profile?.bmi,
        hemoglobinGdl: profile?.hemoglobinGdl,
        systolicMmHg: int.tryParse(_systolicController.text.trim()),
        diastolicMmHg: int.tryParse(_diastolicController.text.trim()),
        hasdiabetes: _diabetes,
        hasEpilepsy: _epilepsy,
        hasCKD: _renal,
        hasHypertension: _hypertension,
        hasHeartDisease: _heartDisease,
        planningPregnancy: _intendsPregnancy,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.result});

  final _AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE2EE), Color(0xFFE7F7FF), Color(0xFFF2ECFF)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 220),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.health_and_safety_outlined, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregnancy readiness',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Text(
                      'MOH-aligned screening for early risk identification and safer pregnancy planning.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RiskBadge(result: result),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.activeIndex});

  final int activeIndex;

  static const steps = [
    'Identify',
    'Assess',
    'Detect risk',
    'Manage',
    'Counsel',
    'Refer',
    'Follow-up',
    'Decision',
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pre-pregnancy care process',
      subtitle:
          'Identification -> assessment -> management -> counselling -> referral -> reassessment.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < steps.length; i++)
            Chip(
              avatar: Icon(
                i <= activeIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
              ),
              label: Text(steps[i]),
              backgroundColor:
                  i <= activeIndex ? const Color(0xFFE6F8F7) : Colors.white,
            ),
        ],
      ),
    );
  }
}

class _AssessmentForm extends StatelessWidget {
  const _AssessmentForm({
    required this.profile,
    required this.ageController,
    required this.systolicController,
    required this.diastolicController,
    required this.medicationController,
    required this.familyHistoryController,
    required this.reproductiveHistoryController,
    required this.intendsPregnancy,
    required this.onPregnancyIntent,
    required this.onChanged,
    required this.flags,
  });

  final Profile? profile;
  final TextEditingController ageController;
  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController medicationController;
  final TextEditingController familyHistoryController;
  final TextEditingController reproductiveHistoryController;
  final bool intendsPregnancy;
  final ValueChanged<bool> onPregnancyIntent;
  final VoidCallback onChanged;
  final List<_FlagState> flags;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Digital first assessment',
      subtitle:
          'Capture history, BP, BMI, medications, lifestyle, psychosocial, chronic disease, family, and reproductive risks.',
      child: Column(
        children: [
          SwitchListTile(
            value: intendsPregnancy,
            onChanged: onPregnancyIntent,
            title: const Text('Planning pregnancy now'),
            subtitle: Text(intendsPregnancy
                ? 'Assess readiness and optimise risk before conception.'
                : 'Support family planning and reassessment.'),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final fields = [
                _NumberField(
                  controller: ageController,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  onChanged: onChanged,
                ),
                _ReadonlyField(
                  label: 'BMI',
                  value: profile == null ? 'Profile pending' : profile!.bmi.toStringAsFixed(1),
                  icon: Icons.straighten,
                ),
                _NumberField(
                  controller: systolicController,
                  label: 'SBP',
                  icon: Icons.favorite_outline,
                  onChanged: onChanged,
                ),
                _NumberField(
                  controller: diastolicController,
                  label: 'DBP',
                  icon: Icons.favorite,
                  onChanged: onChanged,
                ),
              ];
              if (compact) {
                return Column(
                  children: fields
                      .map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: field,
                          ))
                      .toList(),
                );
              }
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.7,
                children: fields,
              );
            },
          ),
          const SizedBox(height: 12),
          _LongField(
            controller: medicationController,
            label: 'Current medications',
            icon: Icons.medication_outlined,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          _LongField(
            controller: familyHistoryController,
            label: 'Family history or genetic concern',
            icon: Icons.family_restroom_outlined,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          _LongField(
            controller: reproductiveHistoryController,
            label: 'Reproductive history',
            icon: Icons.pregnant_woman_outlined,
            onChanged: onChanged,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Risk factors',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final flag in flags)
                FilterChip(
                  selected: flag.value,
                  label: Text(flag.label),
                  onSelected: flag.onChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Risk detection output',
      subtitle:
          'Automatic alerts and readiness guidance based on selected risk factors.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RiskBadge(result: result),
          const SizedBox(height: 12),
          _BulletList(title: 'Detected risks', items: result.risks),
          const SizedBox(height: 12),
          _BulletList(title: 'Recommendations', items: result.recommendations),
        ],
      ),
    );
  }
}

class _CarePlanCard extends StatelessWidget {
  const _CarePlanCard({required this.result});

  final _AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Management, counselling and referral plan',
      subtitle:
          'Use this as a structured conversation aid for healthcare follow-up.',
      child: Column(
        children: [
          const _PlanTile(
            icon: Icons.restaurant_menu_outlined,
            title: 'Nutrition and lifestyle',
            text:
                'Track meals, water, weight, activity, smoking/alcohol exposure, sleep, and stress.',
          ),
          const _PlanTile(
            icon: Icons.medical_services_outlined,
            title: 'Clinical optimisation',
            text:
                'Review chronic conditions, BP, medication safety, investigations, and pregnancy suitability.',
          ),
          const _PlanTile(
            icon: Icons.event_available_outlined,
            title: 'Follow-up and reassessment',
            text:
                'Book reassessment until risk is controlled and pregnancy readiness is confirmed.',
          ),
          if (result.referrals.isNotEmpty)
            _BulletList(title: 'Referral suggestions', items: result.referrals),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DDE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF687386))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.result});

  final _AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.color.withValues(alpha: 24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: result.color.withValues(alpha: 90)),
      ),
      child: Row(
        children: [
          Icon(result.icon, color: result.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.label,
                  style: TextStyle(
                    color: result.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(result.readiness),
              ],
            ),
          ),
          Text(
            '${result.score}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: result.color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Color(0xFF23A6A6)),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE7F7FF),
        child: Icon(icon, color: const Color(0xFF23A6A6)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(text),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LongField extends StatelessWidget {
  const _LongField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _FlagState {
  const _FlagState(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
}

enum _RiskLevel { low, moderate, high }

class _AssessmentResult {
  const _AssessmentResult({
    required this.level,
    required this.score,
    required this.readiness,
    required this.risks,
    required this.recommendations,
    required this.referrals,
    required this.workflowIndex,
  });

  final _RiskLevel level;
  final int score;
  final String readiness;
  final List<String> risks;
  final List<String> recommendations;
  final List<String> referrals;
  final int workflowIndex;

  String get label {
    switch (level) {
      case _RiskLevel.low:
        return 'Low risk';
      case _RiskLevel.moderate:
        return 'Moderate risk';
      case _RiskLevel.high:
        return 'High risk';
    }
  }

  Color get color {
    switch (level) {
      case _RiskLevel.low:
        return const Color(0xFF23A6A6);
      case _RiskLevel.moderate:
        return const Color(0xFFEF8A30);
      case _RiskLevel.high:
        return const Color(0xFFE86D9B);
    }
  }

  IconData get icon {
    switch (level) {
      case _RiskLevel.low:
        return Icons.verified_outlined;
      case _RiskLevel.moderate:
        return Icons.report_problem_outlined;
      case _RiskLevel.high:
        return Icons.priority_high_outlined;
    }
  }
}

// ── Clinical Rule Engine Output Panel ─────────────────────────────────────────

class _ClinicalOutputPanel extends StatelessWidget {
  const _ClinicalOutputPanel({required this.assessment});

  final ClinicalAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(assessment.assessmentDate);
    final healthSummary =
        ClinicalExplanationService.generateHealthSummary(assessment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Overall Status ──────────────────────────────────────────────────
        _OverallStatusCard(assessment: assessment, dateLabel: dateLabel),
        const SizedBox(height: 14),

        // ── AI Health Summary ───────────────────────────────────────────────
        _AIHealthSummaryCard(summary: healthSummary),
        const SizedBox(height: 14),

        // ── Detected Risks ──────────────────────────────────────────────────
        if (assessment.risks.isNotEmpty) ...[
          const _ClinicalSectionTitle(
            icon: Icons.warning_amber_rounded,
            title: 'Detected Risks',
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 8),
          ...assessment.risks.map(
            (risk) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RiskFindingCard(risk: risk),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Clinical Recommendations ────────────────────────────────────────
        if (assessment.recommendations.isNotEmpty) ...[
          const _ClinicalSectionTitle(
            icon: Icons.medical_services_outlined,
            title: 'Clinical Recommendations',
            color: AppTheme.darkPink,
          ),
          const SizedBox(height: 8),
          ...assessment.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecommendationCard(rec: rec),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Nutritional Requirements ────────────────────────────────────────
        const _ClinicalSectionTitle(
          icon: Icons.restaurant_outlined,
          title: 'Nutritional Requirements',
          color: AppTheme.healthcareTeal,
        ),
        const SizedBox(height: 8),
        _NutritionalRequirementsCard(
            nutrition: assessment.nutritionalRequirements),
        const SizedBox(height: 14),

        // ── Medical Disclaimer ──────────────────────────────────────────────
        const _MedicalDisclaimerBanner(),
      ],
    );
  }
}

// ── Overall Status Card ───────────────────────────────────────────────────────

class _OverallStatusCard extends StatelessWidget {
  const _OverallStatusCard({
    required this.assessment,
    required this.dateLabel,
  });

  final ClinicalAssessment assessment;
  final String dateLabel;

  Color get _color {
    switch (assessment.overallRisk) {
      case RiskSeverity.low:
        return AppTheme.success;
      case RiskSeverity.moderate:
        return AppTheme.warning;
      case RiskSeverity.high:
      case RiskSeverity.critical:
        return AppTheme.errorColor;
    }
  }

  IconData get _icon {
    switch (assessment.overallRisk) {
      case RiskSeverity.low:
        return Icons.check_circle;
      case RiskSeverity.moderate:
        return Icons.warning_rounded;
      case RiskSeverity.high:
      case RiskSeverity.critical:
        return Icons.error;
    }
  }

  String get _emoji {
    switch (assessment.overallRisk) {
      case RiskSeverity.low:
        return '🟢';
      case RiskSeverity.moderate:
        return '🟡';
      case RiskSeverity.high:
      case RiskSeverity.critical:
        return '🔴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_emoji  ${assessment.overallRiskLabel}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _MetaChip(label: 'Category', value: 'Clinical Screening'),
              const SizedBox(width: 8),
              const _MetaChip(label: 'Prepared by', value: 'SmartBunda'),
              const SizedBox(width: 8),
              _MetaChip(label: 'Date', value: dateLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF8BBD0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Health Summary Card ───────────────────────────────────────────────────

class _AIHealthSummaryCard extends StatelessWidget {
  const _AIHealthSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5).withValues(alpha: 180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lavender.withValues(alpha: 100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.lavender,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Health Summary',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryText,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _ClinicalSectionTitle extends StatelessWidget {
  const _ClinicalSectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryText,
              ),
        ),
      ],
    );
  }
}

// ── Risk Finding Card ─────────────────────────────────────────────────────────

class _RiskFindingCard extends StatelessWidget {
  const _RiskFindingCard({required this.risk});

  final RiskFinding risk;

  Color get _severityColor {
    switch (risk.severity) {
      case RiskSeverity.low:
        return AppTheme.success;
      case RiskSeverity.moderate:
        return AppTheme.warning;
      case RiskSeverity.high:
        return AppTheme.errorColor;
      case RiskSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  risk.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 80)),
                ),
                child: Text(
                  risk.severityLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Triggered by',
            value: risk.triggeredCondition,
          ),
          if (risk.detail != null) ...[
            const SizedBox(height: 4),
            Text(
              risk.detail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recommendation Card ───────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec});

  final ClinicalRecommendation rec;

  IconData get _categoryIcon {
    switch (rec.category) {
      case RecommendationCategory.supplement:
        return Icons.medication_outlined;
      case RecommendationCategory.nutrition:
        return Icons.restaurant_outlined;
      case RecommendationCategory.lifestyle:
        return Icons.self_improvement_outlined;
      case RecommendationCategory.monitoring:
        return Icons.monitor_heart_outlined;
      case RecommendationCategory.referral:
        return Icons.local_hospital_outlined;
      case RecommendationCategory.general:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.blushGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon, color: AppTheme.darkPink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                _InfoRow(label: 'Purpose', value: rec.purpose),
                if (rec.dose != null)
                  _InfoRow(label: 'Dose', value: rec.dose!),
                if (rec.duration != null)
                  _InfoRow(label: 'Duration', value: rec.duration!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryText,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutritional Requirements Card ─────────────────────────────────────────────

class _NutritionalRequirementsCard extends StatelessWidget {
  const _NutritionalRequirementsCard({required this.nutrition});

  final NutritionalRequirement nutrition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Column(
        children: [
          _NutriRow(
            icon: Icons.local_fire_department_outlined,
            label: 'Energy',
            value: '${nutrition.energyKcal} kcal/day',
            color: AppTheme.darkPink,
          ),
          _NutriRow(
            icon: Icons.fitness_center_outlined,
            label: 'Protein',
            value: '${nutrition.proteinG} g/day',
            color: const Color(0xFF22A6A3),
          ),
          _NutriRow(
            icon: Icons.circle_outlined,
            label: 'Calcium',
            value: '${nutrition.calciumMg} mg/day',
            color: AppTheme.info,
          ),
          _NutriRow(
            icon: Icons.bloodtype_outlined,
            label: 'Iron',
            value: '${nutrition.ironMg} mg/day',
            color: AppTheme.errorColor,
          ),
          _NutriRow(
            icon: Icons.water_drop_outlined,
            label: 'Iodine',
            value: '${nutrition.iodineUg} μg/day',
            color: AppTheme.warning,
          ),
          _NutriRow(
            icon: Icons.science_outlined,
            label: 'Folate',
            value: '${nutrition.folateMcg} μg/day',
            color: AppTheme.success,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _NutriRow extends StatelessWidget {
  const _NutriRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: const Color(0xFFF8BBD0).withValues(alpha: 120),
          ),
      ],
    );
  }
}

// ── Medical Disclaimer ────────────────────────────────────────────────────────

class _MedicalDisclaimerBanner extends StatelessWidget {
  const _MedicalDisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFFF9A825), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This assessment is generated using SmartBunda clinical '
              'screening rules based on Malaysian MOH guidelines. '
              'It does not replace professional medical advice. '
              'Always consult a qualified healthcare provider.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6D4C00),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
