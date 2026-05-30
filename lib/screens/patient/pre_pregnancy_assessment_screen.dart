import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/assessment_input.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/clinical_explanation_service.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/utils/clinical_rules.dart';

/// SmartBunda — Digital First Assessment
///
/// A streamlined, multi-step Material Design 3 wizard collecting only the
/// fields required for maternal risk screening. The final step renders the
/// clinical rule-engine output (risk detection, clinical & nutrition
/// recommendations, AI summary, and medical disclaimer).
class PrePregnancyAssessmentScreen extends ConsumerStatefulWidget {
  const PrePregnancyAssessmentScreen({super.key});

  @override
  ConsumerState<PrePregnancyAssessmentScreen> createState() =>
      _PrePregnancyAssessmentScreenState();
}

class _PrePregnancyAssessmentScreenState
    extends ConsumerState<PrePregnancyAssessmentScreen> {
  static const _stepTitles = [
    'Personal Information',
    'Pregnancy Information',
    'Medical History',
    'Lifestyle Factors',
    'Nutrition Assessment',
    'Laboratory Information',
  ];

  final _input = AssessmentInput();
  final _pageController = PageController();

  // Controllers for numeric fields so the UI keeps text + parsing in sync.
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _caffeineCtrl = TextEditingController();
  final _calciumCtrl = TextEditingController();
  final _ironCtrl = TextEditingController();
  final _iodineCtrl = TextEditingController();
  final _hbCtrl = TextEditingController();

  int _step = 0;
  bool _showResults = false;

  int get _stepCount => _stepTitles.length;

  @override
  void initState() {
    super.initState();
    // Prefill personal/lab fields from the saved profile where available.
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      if (profile.heightCm > 0) {
        _heightCtrl.text = profile.heightCm.toStringAsFixed(0);
        _input.heightCm = profile.heightCm;
      }
      if (profile.currentWeightKg > 0) {
        _weightCtrl.text = profile.currentWeightKg.toStringAsFixed(0);
        _input.weightKg = profile.currentWeightKg;
      }
      if (profile.hemoglobinGdl != null) {
        _hbCtrl.text = profile.hemoglobinGdl!.toStringAsFixed(1);
        _input.hemoglobinGdl = profile.hemoglobinGdl;
      }
      final age = profile.age;
      if (age != null) {
        _ageCtrl.text = age.toString();
        _input.age = age;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _caffeineCtrl.dispose();
    _calciumCtrl.dispose();
    _ironCtrl.dispose();
    _iodineCtrl.dispose();
    _hbCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _persistProfileOverlap();
      setState(() => _showResults = true);
    }
  }

  void _back() {
    if (_showResults) {
      setState(() => _showResults = false);
      return;
    }
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Persist the fields shared with the patient profile (height, weight, Hb).
  void _persistProfileOverlap() {
    final user = ref.read(currentUserProvider);
    final existing = ref.read(profileProvider).valueOrNull;
    if (user == null) return;
    final base = existing;
    if (base == null) return; // Only update when a profile already exists.
    final updated = base.copyWith(
      heightCm: _input.heightCm ?? base.heightCm,
      currentWeightKg: _input.weightKg ?? base.currentWeightKg,
      hemoglobinGdl: _input.hemoglobinGdl ?? base.hemoglobinGdl,
    );
    ref.read(dataStoreProvider).saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBase,
      appBar: AppBar(
        title: const Text('Digital First Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0 && !_showResults) {
              Navigator.of(context).maybePop();
            } else {
              _back();
            }
          },
        ),
      ),
      body: _showResults ? _buildResults() : _buildWizard(),
    );
  }

  // ── Wizard ──────────────────────────────────────────────────────────────────

  Widget _buildWizard() {
    final progress = (_step + 1) / _stepCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_step + 1} of $_stepCount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.darkPink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF8BBD0),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.darkPink),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _stepTitles[_step],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _personalStep(),
              _pregnancyStep(),
              _medicalStep(),
              _lifestyleStep(),
              _nutritionStep(),
              _labStep(),
            ],
          ),
        ),
        _navBar(),
      ],
    );
  }

  Widget _navBar() {
    final isLast = _step == _stepCount - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isLast ? 'View Results' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Steps ───────────────────────────────────────────────────────────────────

  Widget _personalStep() {
    final bmi = _input.bmi;
    return _stepBody(children: [
      _numberField(
        controller: _ageCtrl,
        label: 'Age (years)',
        icon: Icons.cake_outlined,
        onChanged: (v) => setState(() => _input.age = int.tryParse(v)),
      ),
      _numberField(
        controller: _heightCtrl,
        label: 'Height (cm)',
        icon: Icons.height_outlined,
        onChanged: (v) =>
            setState(() => _input.heightCm = double.tryParse(v)),
      ),
      _numberField(
        controller: _weightCtrl,
        label: 'Weight (kg)',
        icon: Icons.monitor_weight_outlined,
        onChanged: (v) =>
            setState(() => _input.weightKg = double.tryParse(v)),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.blushGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calculate_outlined, color: AppTheme.darkPink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Body Mass Index (BMI)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              bmi == null ? '--' : bmi.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkPink,
                  ),
            ),
          ],
        ),
      ),
      if (bmi != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            _bmiCategory(bmi),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
          ),
        ),
    ]);
  }

  Widget _pregnancyStep() {
    return _stepBody(children: [
      _switchTile(
        title: 'Planning pregnancy',
        subtitle: 'Are you planning to conceive?',
        value: _input.planningPregnancy,
        onChanged: (v) => setState(() => _input.planningPregnancy = v),
      ),
      _switchTile(
        title: 'Currently pregnant',
        subtitle: 'Are you pregnant now?',
        value: _input.currentlyPregnant,
        onChanged: (v) => setState(() {
          _input.currentlyPregnant = v;
          if (!v) _input.trimester = null;
          if (v) _input.trimester ??= 1;
        }),
      ),
      if (_input.currentlyPregnant) ...[
        const SizedBox(height: 8),
        Text(
          'Pregnancy Trimester',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('First')),
            ButtonSegment(value: 2, label: Text('Second')),
            ButtonSegment(value: 3, label: Text('Third')),
          ],
          selected: {_input.trimester ?? 1},
          onSelectionChanged: (selection) =>
              setState(() => _input.trimester = selection.first),
        ),
      ],
    ]);
  }

  Widget _medicalStep() {
    return _stepBody(children: [
      _switchTile(
        title: 'Diabetes',
        value: _input.diabetes,
        onChanged: (v) => setState(() => _input.diabetes = v),
      ),
      _switchTile(
        title: 'Epilepsy',
        value: _input.epilepsy,
        onChanged: (v) => setState(() => _input.epilepsy = v),
      ),
      _switchTile(
        title: 'Chronic Kidney Disease',
        value: _input.chronicKidneyDisease,
        onChanged: (v) => setState(() => _input.chronicKidneyDisease = v),
      ),
      _switchTile(
        title: 'Previous Pregnancy Complications',
        value: _input.previousPregnancyComplications,
        onChanged: (v) =>
            setState(() => _input.previousPregnancyComplications = v),
      ),
      _switchTile(
        title: 'Postpartum Hemorrhage History',
        value: _input.postpartumHemorrhageHistory,
        onChanged: (v) =>
            setState(() => _input.postpartumHemorrhageHistory = v),
      ),
    ]);
  }

  Widget _lifestyleStep() {
    return _stepBody(children: [
      _numberField(
        controller: _caffeineCtrl,
        label: 'Daily Caffeine Intake (mg)',
        icon: Icons.coffee_outlined,
        onChanged: (v) =>
            setState(() => _input.dailyCaffeineMg = double.tryParse(v)),
      ),
      _switchTile(
        title: 'Smoking Exposure',
        subtitle: 'Active or passive smoking',
        value: _input.smokingExposure,
        onChanged: (v) => setState(() => _input.smokingExposure = v),
      ),
      _switchTile(
        title: 'Alcohol Exposure',
        value: _input.alcoholExposure,
        onChanged: (v) => setState(() => _input.alcoholExposure = v),
      ),
      const SizedBox(height: 8),
      Text(
        'Physical Activity Level',
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      SegmentedButton<PhysicalActivityLevel>(
        segments: const [
          ButtonSegment(
              value: PhysicalActivityLevel.low, label: Text('Low')),
          ButtonSegment(
              value: PhysicalActivityLevel.moderate, label: Text('Moderate')),
          ButtonSegment(
              value: PhysicalActivityLevel.high, label: Text('High')),
        ],
        selected: _input.physicalActivityLevel == null
            ? <PhysicalActivityLevel>{}
            : {_input.physicalActivityLevel!},
        emptySelectionAllowed: true,
        onSelectionChanged: (selection) => setState(() =>
            _input.physicalActivityLevel =
                selection.isEmpty ? null : selection.first),
      ),
    ]);
  }

  Widget _nutritionStep() {
    return _stepBody(children: [
      Text(
        'Estimate your average daily intake. Leave blank if unknown.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
            ),
      ),
      const SizedBox(height: 8),
      _numberField(
        controller: _calciumCtrl,
        label: 'Calcium Intake (mg/day)',
        icon: Icons.circle_outlined,
        onChanged: (v) =>
            setState(() => _input.calciumMgPerDay = double.tryParse(v)),
      ),
      _numberField(
        controller: _ironCtrl,
        label: 'Iron Intake (mg/day)',
        icon: Icons.bloodtype_outlined,
        onChanged: (v) =>
            setState(() => _input.ironMgPerDay = double.tryParse(v)),
      ),
      _numberField(
        controller: _iodineCtrl,
        label: 'Iodine Intake (μg/day)',
        icon: Icons.water_drop_outlined,
        onChanged: (v) =>
            setState(() => _input.iodineUgPerDay = double.tryParse(v)),
      ),
    ]);
  }

  Widget _labStep() {
    return _stepBody(children: [
      Text(
        'Enter your most recent laboratory result, if available.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
            ),
      ),
      const SizedBox(height: 8),
      _numberField(
        controller: _hbCtrl,
        label: 'Hemoglobin Level (g/dL)',
        icon: Icons.science_outlined,
        onChanged: (v) =>
            setState(() => _input.hemoglobinGdl = double.tryParse(v)),
      ),
    ]);
  }

  // ── Results ─────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final assessment = ClinicalRuleEngine.evaluate(_input.toClinicalInput());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Assessment Results',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your answers and Malaysian MOH screening guidelines.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryText,
              ),
        ),
        const SizedBox(height: 16),
        _ClinicalOutputPanel(assessment: assessment),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit answers'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  // ── Shared input widgets ──────────────────────────────────────────────────────

  Widget _stepBody({required List<Widget> children}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (final child in children) ...[
          child,
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _switchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight (BMI < 18.5)';
    if (bmi < 25) return 'Healthy weight (BMI 18.5–24.9)';
    if (bmi < 30) return 'Overweight (BMI 25–29.9)';
    return 'Obese (BMI ≥ 30)';
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
