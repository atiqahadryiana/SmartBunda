import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/app_user.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

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
  late final TextEditingController _weekCtrl;
  late final TextEditingController _eddCtrl;
  late final TextEditingController _riskCtrl;
  bool _hasAnemia = false;
  bool _hasGdm = false;
  bool _saving = false;
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
    _weekCtrl = TextEditingController();
    _eddCtrl = TextEditingController();
    _riskCtrl = TextEditingController();

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
        setState(() {});
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
        setState(() {});
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
    _weekCtrl.dispose();
    _eddCtrl.dispose();
    _riskCtrl.dispose();
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
    _hasAnemia = profile.medicalConditions.contains(MedicalCondition.anemia);
    _hasGdm = profile.medicalConditions
        .contains(MedicalCondition.gestationalDiabetes);
  }

  void _syncPregnancy(Pregnancy pregnancy) {
    _weekCtrl.text = pregnancy.gestationalWeek.toString();
    _eddCtrl.text = pregnancy.edd;
    _riskCtrl.text = pregnancy.riskLevel;
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

  String? _validateWeek(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.trim().isEmpty) return strings.requiredField;
    final week = int.tryParse(value);
    if (week == null || week < 1 || week > 42) {
      return strings.weekRangeError;
    }
    return null;
  }

  String? _validateDate(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!pattern.hasMatch(trimmed)) {
      return strings.useYmd;
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return strings.invalidDate;
    }
    return null;
  }

  String? _validateOptionalNumber(String? value) {
    final strings = AppStrings.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed) == null ? strings.numberField : null;
  }

  String _trimesterFromWeekLabel(AppStrings strings) {
    final week = int.tryParse(_weekCtrl.text.trim());
    final trimester = week == null ? null : Pregnancy.trimesterFromWeek(week);
    if (trimester == null) return '--';
    final label = strings.trimesterLabel(trimester);
    return strings.isMalay ? 'Trimester $label' : '$label trimester';
  }

  Future<void> _pickEdd(BuildContext context) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 200));
    final existing = DateTime.tryParse(_eddCtrl.text.trim());
    if (existing != null) {
      initialDate = existing;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _eddCtrl.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
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
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar:
          widget.showAppBar ? AppBar(title: Text(strings.editProfile)) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (_) {
            return Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _bloodTypeCtrl,
                    decoration:
                        InputDecoration(labelText: strings.bloodTypeLabel),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.medicalConditions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.anemiaLabel),
                    value: _hasAnemia,
                    onChanged: (v) => setState(() => _hasAnemia = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.gdmLabel),
                    value: _hasGdm,
                    onChanged: (v) => setState(() => _hasGdm = v),
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
                        TextFormField(
                          controller: _weekCtrl,
                          decoration: InputDecoration(
                            labelText: strings.gestationalWeekLabel,
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateWeek,
                          onChanged: (_) => setState(() {}),
                        ),
                        InputDecorator(
                          decoration: InputDecoration(
                              labelText: strings.trimesterLabelText),
                          child: Text(_trimesterFromWeekLabel(strings)),
                        ),
                        TextFormField(
                          controller: _eddCtrl,
                          decoration: InputDecoration(
                            labelText: strings.eddLabel,
                            suffixIcon: IconButton(
                              tooltip: strings.pickDateTooltip,
                              onPressed: () => _pickEdd(context),
                              icon: const Icon(Icons.calendar_month),
                            ),
                          ),
                          keyboardType: TextInputType.datetime,
                          validator: _validateDate,
                        ),
                        TextFormField(
                          controller: _riskCtrl,
                          decoration: InputDecoration(
                              labelText: strings.riskLevelLabel),
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
                                  medicalConditions: {
                                    if (_hasAnemia) MedicalCondition.anemia,
                                    if (_hasGdm)
                                      MedicalCondition.gestationalDiabetes,
                                  },
                                );
                                await ref
                                    .read(dataStoreProvider)
                                    .saveProfile(profile);

                                final weekText = _weekCtrl.text.trim();
                                final eddText = _eddCtrl.text.trim();
                                final riskText = _riskCtrl.text.trim();
                                final hasPregnancyInput = weekText.isNotEmpty ||
                                    eddText.isNotEmpty ||
                                    riskText.isNotEmpty;
                                if (hasPregnancyInput) {
                                  final week = int.tryParse(weekText);
                                  final eddDate = eddText.isEmpty
                                      ? null
                                      : DateTime.tryParse(eddText);
                                  if (week == null) {
                                    throw const FormatException(
                                        'Pregnancy week');
                                  }
                                  if (eddText.isNotEmpty && eddDate == null) {
                                    throw const FormatException('EDD');
                                  }
                                  final pregnancyId = _syncedPregnancy?.id ??
                                      DateTime.now()
                                          .microsecondsSinceEpoch
                                          .toString();
                                  final trimesterIndex =
                                      Pregnancy.trimesterIndexFromWeek(week);
                                  final pregnancy = Pregnancy(
                                    id: pregnancyId,
                                    patientId: user.id,
                                    gestationalWeek: week,
                                    trimester: trimesterIndex,
                                    edd: eddText,
                                    riskLevel: riskText,
                                    updatedAt: DateTime.now(),
                                  );
                                  await ref
                                      .read(dataStoreProvider)
                                      .savePregnancy(pregnancy);
                                }

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(strings.profileSaved)),
                                );
                              } on FormatException catch (e) {
                                if (!context.mounted) return;
                                final label = e.message;
                                final message = label == 'Height/weight'
                                    ? strings.heightWeightNumberError
                                    : (label == 'Pregnancy week'
                                        ? strings.weekNumberError
                                        : strings.eddInvalidError);
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
    );
  }
}
