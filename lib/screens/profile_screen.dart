import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/screen_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _bloodTypeCtrl;
  late final TextEditingController _weekCtrl;
  late final TextEditingController _eddCtrl;
  late final TextEditingController _riskCtrl;
  int _trimester = 2;
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
    _bloodTypeCtrl.text = profile.bloodType;
    _hasAnemia = profile.medicalConditions.contains(MedicalCondition.anemia);
    _hasGdm = profile.medicalConditions.contains(MedicalCondition.gestationalDiabetes);
  }

  void _syncPregnancy(Pregnancy pregnancy) {
    _weekCtrl.text = pregnancy.gestationalWeek.toString();
    _trimester = pregnancy.trimester;
    _eddCtrl.text = pregnancy.edd;
    _riskCtrl.text = pregnancy.riskLevel;
  }

  double? _currentBmi() {
    final heightCm = double.tryParse(_heightCtrl.text);
    final weightKg = double.tryParse(_weightCtrl.text);
    if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String? _validateWeek(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final week = int.tryParse(value);
    if (week == null || week < 1 || week > 42) {
      return 'Week must be 1 to 42';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final trimmed = value.trim();
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Use YYYY-MM-DD';
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return 'Invalid date';
    }
    return null;
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
    final profileAsync = ref.watch(profileProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);
    final bmi = _currentBmi();

    if (user != null && user.role != UserRole.patient) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Account')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const ScreenHeader(
                title: 'Account',
                subtitle: 'Manage your profile details and role settings.',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(user.email),
                  trailing: Text(user.role.label),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Patient pregnancy profiles are managed on the patient profile module.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Profile')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (_) {
            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  const ScreenHeader(
                    title: 'Patient profile',
                    subtitle: 'Complete your details to personalize nutrition targets.',
                    icon: Icons.favorite_border,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth (YYYY-MM-DD)',
                    ),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightCtrl,
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && double.tryParse(v) != null ? null : 'Number',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && double.tryParse(v) != null ? null : 'Number',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'BMI'),
                    child: Text(bmi == null ? '--' : bmi.toStringAsFixed(1)),
                  ),
                  TextFormField(
                    controller: _bloodTypeCtrl,
                    decoration: const InputDecoration(labelText: 'Blood type'),
                  ),
                  const SizedBox(height: 12),
                  Text('Medical conditions', style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Anemia'),
                    value: _hasAnemia,
                    onChanged: (v) => setState(() => _hasAnemia = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gestational diabetes'),
                    value: _hasGdm,
                    onChanged: (v) => setState(() => _hasGdm = v),
                  ),
                  const SizedBox(height: 16),
                  Text('Pregnancy', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  pregnancyAsync.when(
                    data: (_) => Column(
                      children: [
                        TextFormField(
                          controller: _weekCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Gestational week'),
                          keyboardType: TextInputType.number,
                          validator: _validateWeek,
                        ),
                        DropdownButtonFormField<int>(
                          initialValue: _trimester,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Trimester 1')),
                            DropdownMenuItem(value: 2, child: Text('Trimester 2')),
                            DropdownMenuItem(value: 3, child: Text('Trimester 3')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _trimester = value);
                          },
                          decoration: const InputDecoration(labelText: 'Trimester'),
                        ),
                        TextFormField(
                          controller: _eddCtrl,
                          decoration: InputDecoration(
                            labelText: 'EDD (YYYY-MM-DD)',
                            suffixIcon: IconButton(
                              tooltip: 'Pick date',
                              onPressed: () => _pickEdd(context),
                              icon: const Icon(Icons.calendar_month),
                            ),
                          ),
                          keyboardType: TextInputType.datetime,
                          validator: _validateDate,
                        ),
                        TextFormField(
                          controller: _riskCtrl,
                          decoration: const InputDecoration(labelText: 'Risk level'),
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: user == null || _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _saving = true);
                              try {
                                final profile = Profile(
                                  patientId: user.id,
                                  dob: _dobCtrl.text.trim(),
                                  heightCm: double.parse(_heightCtrl.text),
                                  currentWeightKg: double.parse(_weightCtrl.text),
                                  bloodType: _bloodTypeCtrl.text.trim(),
                                  medicalConditions: {
                                    if (_hasAnemia) MedicalCondition.anemia,
                                    if (_hasGdm) MedicalCondition.gestationalDiabetes,
                                  },
                                );
                                await ref.read(dataStoreProvider).saveProfile(profile);

                                final pregnancyId = _syncedPregnancy?.id ??
                                    DateTime.now().microsecondsSinceEpoch.toString();
                                final pregnancy = Pregnancy(
                                  id: pregnancyId,
                                  patientId: user.id,
                                  gestationalWeek: int.parse(_weekCtrl.text),
                                  trimester: _trimester,
                                  edd: _eddCtrl.text.trim(),
                                  riskLevel: _riskCtrl.text.trim(),
                                  updatedAt: DateTime.now(),
                                );
                                await ref.read(dataStoreProvider).savePregnancy(pregnancy);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile saved')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Save failed: $e')),
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
                          : const Text('Save profile'),
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
