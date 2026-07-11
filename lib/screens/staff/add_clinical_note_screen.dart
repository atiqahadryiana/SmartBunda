import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/clinical_note.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';
import 'package:smartbunda/widgets/unsaved_changes_guard.dart';

/// Staff-side screen to author a clinical note for a patient and review past
/// notes. The patient sees saved notes read-only in their Medical Records.
class AddClinicalNoteScreen extends ConsumerStatefulWidget {
  const AddClinicalNoteScreen({super.key, required this.patient});

  final AppUser patient;

  @override
  ConsumerState<AddClinicalNoteScreen> createState() =>
      _AddClinicalNoteScreenState();
}

class _AddClinicalNoteScreenState
    extends ConsumerState<AddClinicalNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  final _nutritionCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _nutritionCtrl.dispose();
    _followUpCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await _saveNote(
      clinicalNote: _noteCtrl.text.trim(),
      nutritionRecommendation: _textOrNull(_nutritionCtrl),
      followUpInstruction: _textOrNull(_followUpCtrl),
    );
    if (!mounted) return;
    if (saved) {
      _noteCtrl.clear();
      _nutritionCtrl.clear();
      _followUpCtrl.clear();
    }
    setState(() => _saving = false);
  }

  /// Persists a new clinical note for this patient, authored by the current
  /// staff member. Returns true on success. Shared by the top form and the
  /// "add follow-up" sheet.
  Future<bool> _saveNote({
    required String clinicalNote,
    String? nutritionRecommendation,
    String? followUpInstruction,
  }) async {
    final staff = ref.read(currentUserProvider);
    if (staff == null) return false;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now();
      final note = ClinicalNote(
        id: 'note_${now.microsecondsSinceEpoch}',
        patientId: widget.patient.id,
        professionalId: staff.id,
        professionalName: staff.displayName ?? staff.email,
        clinicalNote: clinicalNote,
        nutritionRecommendation: nutritionRecommendation,
        followUpInstruction: followUpInstruction,
        createdAt: now,
      );
      await ref.read(clinicalNoteRepositoryProvider).add(note);
      if (!mounted) return true;
      messenger.showSnackBar(
        const SnackBar(content: Text('Clinical note saved.')),
      );
      return true;
    } catch (e, stack) {
      final detail = e is FirebaseException
          ? '[${e.code}] ${e.message ?? ''}'
          : '$e';
      debugPrint('[AddClinicalNote] save failed: $detail\n$stack');
      if (!mounted) return false;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save: $detail'),
          duration: const Duration(seconds: 8),
        ),
      );
      return false;
    }
  }

  /// Bottom sheet with a text box to add a follow-up note for this patient,
  /// opened by tapping an existing note. [previous] is the note being followed
  /// up (shown for context).
  Future<void> _showAddFollowUpSheet(ClinicalNote previous) async {
    final controller = TextEditingController();
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final text = Theme.of(sheetContext).textTheme;
            final scheme = Theme.of(sheetContext).colorScheme;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.m,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add follow-up note', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'For ${widget.patient.displayName ?? widget.patient.email} '
                    '· following up on the note from ${previous.professionalName} '
                    '(${DateFormat('d MMM yyyy').format(previous.createdAt)}).',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up note',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SbLoadingButton(
                    label: 'Add Note',
                    icon: Icons.add_comment_outlined,
                    loading: saving,
                    onPressed: () async {
                      final body = controller.text.trim();
                      if (body.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Enter a note first.')),
                        );
                        return;
                      }
                      setSheetState(() => saving = true);
                      final ok = await _saveNote(clinicalNote: body);
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      } else {
                        setSheetState(() => saving = false);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  String? _textOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync =
        ref.watch(patientClinicalNotesProvider(widget.patient.id));
    final name = widget.patient.displayName ?? widget.patient.email;

    return PopScope(
      canPop: _noteCtrl.text.trim().isEmpty &&
          _nutritionCtrl.text.trim().isEmpty &&
          _followUpCtrl.text.trim().isEmpty,
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
      child: Scaffold(
        appBar: AppBar(title: Text('Notes — $name')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.xl),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New clinical note',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: _noteCtrl,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Clinical note',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v != null && v.trim().isNotEmpty) ? null : 'Required',
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: _nutritionCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Nutrition recommendation (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: _followUpCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up instructions (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SbLoadingButton(
                    label: 'Save Note',
                    icon: Icons.save_outlined,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Previous notes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            notesAsync.when(
              data: (notes) => notes.isEmpty
                  ? Text('No notes yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : Column(
                      children: [
                        for (final n in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s),
                            child: ClinicalNoteCard(
                              note: n,
                              onTap: () => _showAddFollowUpSheet(n),
                            ),
                          ),
                      ],
                    ),
              loading: () =>
                  const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared card rendering a single clinical note (staff & patient views).
///
/// Pass [onTap] (staff only) to make the card tappable — e.g. to add a
/// follow-up note for the same patient. Left null (the patient view) the card
/// stays read-only.
class ClinicalNoteCard extends StatelessWidget {
  const ClinicalNoteCard({super.key, required this.note, this.onTap});

  final ClinicalNote note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SbCard(
      onTap: onTap,
      semanticLabel: onTap == null ? null : 'Add follow-up note',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information_outlined,
                  size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(note.professionalName, style: text.titleSmall),
              ),
              Text(DateFormat('d MMM yyyy').format(note.createdAt),
                  style:
                      text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(note.clinicalNote, style: text.bodyMedium?.copyWith(height: 1.45)),
          if (note.nutritionRecommendation != null) ...[
            const SizedBox(height: AppSpacing.s),
            _labelled(context, 'Nutrition', note.nutritionRecommendation!),
          ],
          if (note.followUpInstruction != null) ...[
            const SizedBox(height: AppSpacing.s),
            _labelled(context, 'Follow-up', note.followUpInstruction!),
          ],
          if (onTap != null) ...[
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Icon(Icons.add_comment_outlined,
                    size: 15, color: scheme.primary),
                const SizedBox(width: 6),
                Text('Tap to add a follow-up note',
                    style: text.labelSmall?.copyWith(color: scheme.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelled(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.labelMedium
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
        Text(value, style: text.bodyMedium?.copyWith(height: 1.45)),
      ],
    );
  }
}
