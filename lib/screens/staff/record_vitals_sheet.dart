/// SmartBunda — nurse "Record vitals" form (per-appointment).
///
/// A staff member (typically a nurse) records the pregnant mother's key
/// measurements at an appointment. On save it:
///   1. writes a per-visit [AppointmentVitals] snapshot (history), and
///   2. updates the live [Profile] (weight / Hb / abdominal circumference) so
///      the patient dashboard, BMI, and targets reflect the latest reading.
///
/// Gestational week, when entered, also updates the [Pregnancy] record.
library smartbunda.record_vitals_sheet;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment_vitals.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/unsaved_changes_guard.dart';

/// Opens the record-vitals form as a modal bottom sheet. Returns true if a
/// record was saved.
Future<bool?> showRecordVitalsSheet(
  BuildContext context,
  WidgetRef ref, {
  required AppUser patient,
  required Profile? profile,
  required Pregnancy? pregnancy,
  String? appointmentId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordVitalsSheet(
      patient: patient,
      profile: profile,
      pregnancy: pregnancy,
      appointmentId: appointmentId,
    ),
  );
}

class _RecordVitalsSheet extends ConsumerStatefulWidget {
  const _RecordVitalsSheet({
    required this.patient,
    required this.profile,
    required this.pregnancy,
    required this.appointmentId,
  });

  final AppUser patient;
  final Profile? profile;
  final Pregnancy? pregnancy;
  final String? appointmentId;

  @override
  ConsumerState<_RecordVitalsSheet> createState() => _RecordVitalsSheetState();
}

class _RecordVitalsSheetState extends ConsumerState<_RecordVitalsSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _weight =
      TextEditingController(text: _initial(widget.profile?.currentWeightKg));
  late final TextEditingController _hb =
      TextEditingController(text: _initial(widget.profile?.hemoglobinGdl));
  late final TextEditingController _abdomen = TextEditingController(
      text: _initial(widget.profile?.abdominalCircumferenceCm));
  late final TextEditingController _fundal = TextEditingController();
  late final TextEditingController _systolic = TextEditingController();
  late final TextEditingController _diastolic = TextEditingController();
  late final TextEditingController _week = TextEditingController(
      text: widget.pregnancy?.gestationalWeek != null &&
              widget.pregnancy!.gestationalWeek > 0
          ? '${widget.pregnancy!.gestationalWeek}'
          : '');
  final _notes = TextEditingController();

  /// Last menstrual period — establishes pregnancy dating. When set, the
  /// pregnancy's gestational week + EDD are derived from it. Seeded from the
  /// existing pregnancy record.
  late DateTime? _lmp = widget.pregnancy?.lmp;

  bool _saving = false;
  bool _hasUnsavedChanges = false;

  static String _initial(double? value) {
    if (value == null || value <= 0) return '';
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weight.dispose();
    _hb.dispose();
    _abdomen.dispose();
    _fundal.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _week.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _updateUnsavedChanges() {
    setState(() {
      _hasUnsavedChanges = _weight.text.trim().isNotEmpty ||
          _hb.text.trim().isNotEmpty ||
          _abdomen.text.trim().isNotEmpty ||
          _fundal.text.trim().isNotEmpty ||
          _systolic.text.trim().isNotEmpty ||
          _diastolic.text.trim().isNotEmpty ||
          _week.text.trim().isNotEmpty ||
          _lmp != widget.pregnancy?.lmp ||
          _notes.text.trim().isNotEmpty;
    });
  }

  double? _double(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _int(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  String _lmpLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Date picker for the last menstrual period — bounded to a valid pregnancy
  /// window (no future dates, at most ~45 weeks back).
  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? now.subtract(const Duration(days: 7 * 8)),
      firstDate: now.subtract(const Duration(days: 7 * 45)),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _lmp = picked);
    _updateUnsavedChanges();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final viewer = ref.read(currentUserProvider);
    if (viewer == null) return;

    final weight = _double(_weight);
    final hb = _double(_hb);
    final abdomen = _double(_abdomen);
    final fundal = _double(_fundal);
    final systolic = _int(_systolic);
    final diastolic = _int(_diastolic);
    final week = _int(_week);
    final notes = _notes.text.trim();

    setState(() {
      _saving = true;
      _hasUnsavedChanges = false;
    });
    try {
      final ts = DateTime.now();
      final id = ts.microsecondsSinceEpoch.toString();

      // 1. Per-visit vitals snapshot (history).
      final vitals = AppointmentVitals(
        id: id,
        patientId: widget.patient.id,
        recordedBy: viewer.id,
        recordedByName: viewer.displayName ?? viewer.email,
        recordedAt: ts,
        appointmentId: widget.appointmentId,
        weightKg: weight,
        hemoglobinGdl: hb,
        systolicBp: systolic,
        diastolicBp: diastolic,
        fundalHeightCm: fundal,
        gestationalWeek: week,
        notes: notes.isEmpty ? null : notes,
      );
      await ref.read(appointmentVitalsRepositoryProvider).add(vitals);

      // 2. Update the live profile so dashboard/BMI/targets stay current.
      //    Only overwrite fields the nurse actually entered. If the patient has
      //    no profile yet, create a minimal one so Hb/weight are still saved
      //    (saveProfile upserts with merge:true).
      if (weight != null || hb != null || abdomen != null) {
        final base = widget.profile;
        final updated = base != null
            ? base.copyWith(
                currentWeightKg: weight ?? base.currentWeightKg,
                hemoglobinGdl: hb ?? base.hemoglobinGdl,
                abdominalCircumferenceCm:
                    abdomen ?? base.abdominalCircumferenceCm,
              )
            : Profile(
                patientId: widget.patient.id,
                dob: '',
                heightCm: 0,
                currentWeightKg: weight ?? 0,
                bloodType: '',
                hemoglobinGdl: hb,
                abdominalCircumferenceCm: abdomen,
              );
        await ref.read(dataStoreProvider).saveProfile(updated);
      }

      // 3. Update pregnancy DATING from the LMP, if the nurse set/changed it.
      //    The pregnancy's gestational week + EDD are derived from the LMP (one
      //    source of truth) — the numeric week above is kept only as a
      //    point-in-time vitals observation, not written onto the pregnancy.
      final preg = widget.pregnancy;
      if (preg != null && _lmp != preg.lmp) {
        final derivedWeek = Pregnancy.gestationalWeekFromLmp(_lmp);
        final edd = Pregnancy.eddFromLmp(_lmp);
        final eddText = edd == null
            ? preg.edd
            : '${edd.year}-${edd.month.toString().padLeft(2, '0')}-'
                '${edd.day.toString().padLeft(2, '0')}';
        await ref.read(dataStoreProvider).savePregnancy(
              preg.copyWith(
                lmp: _lmp,
                gestationalWeek: derivedWeek,
                trimester: Pregnancy.trimesterIndexFromWeek(derivedWeek),
                edd: eddText,
                updatedAt: ts,
              ),
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals recorded.')),
      );
    } catch (error, stack) {
      // Surface the precise cause — a Firestore permission denial reports
      // code 'permission-denied'; anything else points to a different problem.
      final detail = error is FirebaseException
          ? '[${error.code}] ${error.message ?? ''}'
          : '$error';
      debugPrint('[RecordVitals] save failed: $detail\n$stack');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vitals: $detail'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patient.displayName ?? widget.patient.email;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => const UnsavedChangesDialog(),
            ) ??
            false;

        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Record vitals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$name • ${_dateLabel(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.profile == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No patient profile on file — vitals will be recorded as '
                        'a visit snapshot only (the profile will not be updated).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _numField(_weight, 'Weight', 'kg', decimal: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numField(_hb, 'Hemoglobin', 'g/dL',
                            decimal: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(_systolic, 'Systolic BP', 'mmHg'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numField(_diastolic, 'Diastolic BP', 'mmHg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(_fundal, 'Fundal height', 'cm',
                            decimal: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numField(_abdomen, 'Abdominal circ.', 'cm',
                            decimal: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // LMP date — establishes pregnancy dating. Gestational week &
                  // EDD on the patient record are derived from this.
                  InkWell(
                    onTap: _pickLmp,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Last menstrual period (LMP)',
                        helperText: _lmp == null
                            ? 'Sets gestational week & EDD automatically.'
                            : 'Pregnancy dating: week ${Pregnancy.gestationalWeekFromLmp(_lmp)}.',
                        helperMaxLines: 2,
                        suffixIcon: const Icon(Icons.calendar_month),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(_lmp == null ? 'Not set' : _lmpLabel(_lmp!)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _numField(_week, 'Gestational week (this visit)', 'weeks'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    onChanged: (_) => _updateUnsavedChanges(),
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save vitals'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController controller,
    String label,
    String unit, {
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      onChanged: (_) => _updateUnsavedChanges(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) {
        final t = value?.trim() ?? '';
        if (t.isEmpty) return null; // all fields optional
        final n = double.tryParse(t);
        if (n == null) return 'Number';
        if (n < 0) return 'Invalid';
        return null;
      },
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
