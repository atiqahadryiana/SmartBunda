import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

/// The eight standard ABO/Rh blood groups, shown in the blood-type dropdown.
const _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _hemoglobinCtrl;
  late final TextEditingController _abdominalCircumferenceCtrl;
  late final TextEditingController _bloodTypeCtrl;
  /// Last menstrual period — the single input that drives gestational week and
  /// EDD (both auto-computed). Null until the patient picks a date.
  DateTime? _lmp;
  /// MOH colour-coded obstetric risk level (dropdown). Null = not set.
  PregnancyRiskLevel? _riskLevel;
  /// Selected pregnancy-related conditions (multi-select dropdown).
  final Set<MedicalCondition> _conditions = {};
  bool _saving = false;
  // True once the user edits a field; gates the unsaved-changes guard. Reset
  // after a successful save and when the form re-syncs from the backend.
  bool _dirty = false;
  Profile? _syncedProfile;
  Pregnancy? _syncedPregnancy;

  @override
  void initState() {
    super.initState();
    _dobCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _hemoglobinCtrl = TextEditingController();
    _abdominalCircumferenceCtrl = TextEditingController();
    _bloodTypeCtrl = TextEditingController();

    final profileNow = ref.read(profileProvider).valueOrNull;
    if (profileNow != null) {
      _syncedProfile = profileNow;
      _syncProfile(profileNow);
    }

    final pregnancyNow = ref.read(pregnancyProvider).valueOrNull;
    if (pregnancyNow != null) {
      _syncedPregnancy = pregnancyNow;
      _syncPregnancy(pregnancyNow);
    }

    ref.listen<AsyncValue<Profile?>>(profileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile == null || identical(profile, _syncedProfile)) {
        if (profile == null) _syncedProfile = null;
        return;
      }
      _syncedProfile = profile;
      _syncProfile(profile);
      if (mounted) {
        setState(() => _dirty = false);
      }
    });

    ref.listen<AsyncValue<Pregnancy?>>(pregnancyProvider, (previous, next) {
      final pregnancy = next.valueOrNull;
      if (pregnancy == null || identical(pregnancy, _syncedPregnancy)) {
        if (pregnancy == null) _syncedPregnancy = null;
        return;
      }
      _syncedPregnancy = pregnancy;
      _syncPregnancy(pregnancy);
      if (mounted) {
        setState(() => _dirty = false);
      }
    });
  }

  @override
  void dispose() {
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _hemoglobinCtrl.dispose();
    _abdominalCircumferenceCtrl.dispose();
    _bloodTypeCtrl.dispose();
    super.dispose();
  }

  void _syncProfile(Profile profile) {
    _dobCtrl.text = profile.dob;
    _heightCtrl.text = profile.heightCm.toStringAsFixed(1);
    _weightCtrl.text = profile.currentWeightKg.toStringAsFixed(1);
    _hemoglobinCtrl.text = profile.hemoglobinGdl?.toStringAsFixed(1) ?? '';
    _abdominalCircumferenceCtrl.text =
        profile.abdominalCircumferenceCm?.toStringAsFixed(1) ?? '';
    _bloodTypeCtrl.text = profile.bloodType;
    _conditions
      ..clear()
      ..addAll(profile.medicalConditions);
  }

  void _syncPregnancy(Pregnancy pregnancy) {
    _lmp = pregnancy.lmp;
    _riskLevel = PregnancyRiskLevel.fromCode(pregnancy.riskLevel);
  }

  double? _currentBmi() {
    final heightCm = double.tryParse(_heightCtrl.text);
    final weightKg = double.tryParse(_weightCtrl.text);
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String? _validateOptionalNumber(String? value) {
    final strings = AppStrings.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed) == null ? strings.numberField : null;
  }

  String _lmpLabelText() {
    final lmp = _lmp;
    if (lmp == null) return '--';
    final month = lmp.month.toString().padLeft(2, '0');
    final day = lmp.day.toString().padLeft(2, '0');
    return '${lmp.year}-$month-$day';
  }

  /// MOH colour-code swatch for the risk-level dropdown.
  Color _riskColor(PregnancyRiskLevel level) {
    switch (level) {
      case PregnancyRiskLevel.white:
        return Colors.white;
      case PregnancyRiskLevel.green:
        return const Color(0xFF4CAF50);
      case PregnancyRiskLevel.yellow:
        return const Color(0xFFFFEB3B);
      case PregnancyRiskLevel.red:
        return const Color(0xFFE53935);
    }
  }

  /// Gestational week derived from the picked LMP (0 when unset).
  int get _computedWeek => Pregnancy.gestationalWeekFromLmp(_lmp);

  String _computedWeekLabel(AppStrings strings) =>
      _lmp == null ? '--' : strings.weeksValue(_computedWeek);

  String _trimesterFromLmpLabel(AppStrings strings) {
    final trimester = Pregnancy.trimesterFromWeek(_computedWeek);
    if (_lmp == null || trimester == null) return '--';
    final label = strings.trimesterLabel(trimester);
    return strings.isMalay ? 'Trimester $label' : '$label trimester';
  }

  String _computedEddLabel() {
    final edd = Pregnancy.eddFromLmp(_lmp);
    if (edd == null) return '--';
    final month = edd.month.toString().padLeft(2, '0');
    final day = edd.day.toString().padLeft(2, '0');
    return '${edd.year}-$month-$day';
  }

  /// Date picker for the last menstrual period — drives week and EDD.
  Future<void> _pickLmp(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _lmp ?? now.subtract(const Duration(days: 7 * 8));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // A pregnancy spans at most ~42 weeks; an LMP older than that is invalid.
      firstDate: now.subtract(const Duration(days: 7 * 45)),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _lmp = picked;
      _dirty = true;
    });
  }

  /// Multi-select checklist of common pregnancy conditions, shown as a modal
  /// sheet. Updates [_conditions] live as the user toggles items.
  Future<void> _pickConditions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Medical conditions',
                          style: Theme.of(sheetContext).textTheme.titleMedium),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).maybePop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in MedicalCondition.values)
                      CheckboxListTile(
                        title: Text(c.label),
                        value: _conditions.contains(c),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setSheetState(() {});
                          setState(() {
                            if (checked ?? false) {
                              _conditions.add(c);
                            } else {
                              _conditions.remove(c);
                            }
                            _dirty = true;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final strings = AppStrings.of(context);
    final profileAsync = ref.watch(profileProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);
    final bmi = _currentBmi();

    final child = user == null
        ? const SizedBox.shrink()
        : _editView(context, user, profileAsync, pregnancyAsync, bmi);
    return RequireSignIn(
      title: strings.editProfile,
      showAppBar: widget.showAppBar,
      message: strings.signInToEditProfile,
      child: child,
    );
  }

  Widget _editView(
    BuildContext context,
    AppUser user,
    AsyncValue<Profile?> profileAsync,
    AsyncValue<Pregnancy?> pregnancyAsync,
    double? bmi,
  ) {
    final strings = AppStrings.of(context);
    if (user.role != UserRole.patient) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: Text(strings.accountTitle))
            : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              ScreenHeader(
                title: strings.accountTitle,
                subtitle: strings.accountSubtitle,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(user.email),
                  trailing: Text(strings.roleLabel(user.role)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.pregnancyModuleNote,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      appBar:
          widget.showAppBar ? AppBar(title: Text(strings.editProfile)) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (_) {
            return Form(
              key: _formKey,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: ListView(
                children: [
                  ScreenHeader(
                    title: strings.patientProfileTitle,
                    subtitle: strings.patientProfileSubtitle,
                    icon: Icons.favorite_border,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobCtrl,
                    decoration: InputDecoration(
                      labelText: strings.dobLabel,
                    ),
                    validator: (v) => v != null && v.trim().isNotEmpty
                        ? null
                        : strings.requiredField,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightCtrl,
                          decoration:
                              InputDecoration(labelText: strings.heightLabel),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && double.tryParse(v) != null
                                  ? null
                                  : strings.numberField,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          decoration:
                              InputDecoration(labelText: strings.weightLabel),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && double.tryParse(v) != null
                                  ? null
                                  : strings.numberField,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(labelText: strings.bmiLabel),
                    child: Text(bmi == null ? '--' : bmi.toStringAsFixed(1)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hemoglobinCtrl,
                          decoration: InputDecoration(
                              labelText: strings.hemoglobinLabel),
                          keyboardType: TextInputType.number,
                          validator: _validateOptionalNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _abdominalCircumferenceCtrl,
                          decoration: InputDecoration(
                            labelText: strings.abdominalCircumferenceLabel,
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateOptionalNumber,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    // Value is mirrored into _bloodTypeCtrl so the existing
                    // save logic is unchanged. Unknown/legacy text → no
                    // selection (shows the hint) rather than crashing.
                    initialValue: _bloodTypeOptions
                            .contains(_bloodTypeCtrl.text.trim())
                        ? _bloodTypeCtrl.text.trim()
                        : null,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: strings.bloodTypeLabel),
                    hint: Text(strings.t('Select blood type')),
                    items: [
                      for (final type in _bloodTypeOptions)
                        DropdownMenuItem(value: type, child: Text(type)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _bloodTypeCtrl.text = value;
                        _dirty = true;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.medicalConditions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickConditions,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select conditions',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: _conditions.isEmpty
                          ? Text(
                              'None selected',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in _conditions)
                                  Chip(
                                    label: Text(c.label),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onDeleted: () =>
                                        setState(() => _conditions.remove(c)),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.pregnancySectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  pregnancyAsync.when(
                    data: (_) => Column(
                      children: [
                        // LMP date picker — the single input. Gestational week
                        // and EDD below are derived from it automatically.
                        InkWell(
                          onTap: () => _pickLmp(context),
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: strings.lmpLabel,
                              suffixIcon: const Icon(Icons.calendar_month),
                            ),
                            child: Text(_lmpLabelText()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: strings.gestationalWeekLabel,
                                ),
                                child: Text(_computedWeekLabel(strings)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    labelText: strings.trimesterLabelText),
                                child: Text(_trimesterFromLmpLabel(strings)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: InputDecoration(labelText: strings.eddLabel),
                          child: Text(_computedEddLabel()),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PregnancyRiskLevel>(
                          initialValue: _riskLevel,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: strings.riskLevelLabel,
                          ),
                          items: [
                            for (final level in PregnancyRiskLevel.values)
                              DropdownMenuItem(
                                value: level,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _riskColor(level),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(level.label),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() {
                            _riskLevel = value;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _RiskLevelReference(
                          selected: _riskLevel,
                          colorOf: _riskColor,
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _saving = true);
                              try {
                                final heightText = _heightCtrl.text.trim();
                                final weightText = _weightCtrl.text.trim();
                                final height = double.tryParse(heightText);
                                final weight = double.tryParse(weightText);
                                final hemoglobin = double.tryParse(
                                  _hemoglobinCtrl.text.trim(),
                                );
                                final abdominalCircumference = double.tryParse(
                                  _abdominalCircumferenceCtrl.text.trim(),
                                );
                                if (height == null || weight == null) {
                                  throw const FormatException('Height/weight');
                                }
                                final profile = Profile(
                                  patientId: user.id,
                                  dob: _dobCtrl.text.trim(),
                                  heightCm: height,
                                  currentWeightKg: weight,
                                  bloodType: _bloodTypeCtrl.text.trim(),
                                  hemoglobinGdl: hemoglobin,
                                  abdominalCircumferenceCm:
                                      abdominalCircumference,
                                  medicalConditions: Set.of(_conditions),
                                );
                                await ref
                                    .read(dataStoreProvider)
                                    .saveProfile(profile);

                                // Pregnancy details derive from the LMP date
                                // (gestational week + EDD) plus the chosen risk
                                // level. Persist only when at least one is set.
                                final lmp = _lmp;
                                final hasPregnancyInput =
                                    lmp != null || _riskLevel != null;
                                if (hasPregnancyInput) {
                                  final week =
                                      Pregnancy.gestationalWeekFromLmp(lmp);
                                  final eddDate = Pregnancy.eddFromLmp(lmp);
                                  final eddText = eddDate == null
                                      ? ''
                                      : '${eddDate.year}-'
                                          '${eddDate.month.toString().padLeft(2, '0')}-'
                                          '${eddDate.day.toString().padLeft(2, '0')}';
                                  final pregnancyId = _syncedPregnancy?.id ??
                                      DateTime.now()
                                          .microsecondsSinceEpoch
                                          .toString();
                                  final pregnancy = Pregnancy(
                                    id: pregnancyId,
                                    patientId: user.id,
                                    gestationalWeek: week,
                                    trimester:
                                        Pregnancy.trimesterIndexFromWeek(week),
                                    edd: eddText,
                                    riskLevel: _riskLevel?.code ?? '',
                                    updatedAt: DateTime.now(),
                                    lmp: lmp,
                                  );
                                  await ref
                                      .read(dataStoreProvider)
                                      .savePregnancy(pregnancy);
                                }

                                _dirty = false; // saved → no unsaved changes
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(strings.profileSaved)),
                                );
                              } on FormatException catch (e) {
                                if (!context.mounted) return;
                                // The only structured failure left is a bad
                                // height/weight number; everything else falls
                                // through to the generic catch below.
                                final message = e.message == 'Height/weight'
                                    ? strings.heightWeightNumberError
                                    : strings.saveFailed(e.message);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(strings.saveFailed(message))),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(strings.saveFailed('$e'))),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.saveProfile),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      ),
    );
  }

  /// Asks the user to confirm leaving with unsaved edits.
  Future<bool> _confirmDiscard() async {
    final strings = AppStrings.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('Discard changes?')),
        content: Text(
          strings.t('You have unsaved changes. Leave without saving?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.t('Keep editing')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.t('Discard')),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}

/// Reference panel for the MOH 4-tier obstetric colour coding. Lists every
/// tier (colour swatch + label + care meaning); the patient's selected tier is
/// highlighted. Collapsed by default to keep the form compact.
class _RiskLevelReference extends StatefulWidget {
  const _RiskLevelReference({required this.selected, required this.colorOf});

  final PregnancyRiskLevel? selected;
  final Color Function(PregnancyRiskLevel) colorOf;

  @override
  State<_RiskLevelReference> createState() => _RiskLevelReferenceState();
}

class _RiskLevelReferenceState extends State<_RiskLevelReference> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('MOH colour-coding guide',
                        style: text.labelLarge),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  for (final level in PregnancyRiskLevel.values)
                    _RiskTierRow(
                      level: level,
                      color: widget.colorOf(level),
                      highlighted: widget.selected == level,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskTierRow extends StatelessWidget {
  const _RiskTierRow({
    required this.level,
    required this.color,
    required this.highlighted,
  });

  final PregnancyRiskLevel level;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? scheme.primary : scheme.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.label,
                    style: text.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  level.description,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
