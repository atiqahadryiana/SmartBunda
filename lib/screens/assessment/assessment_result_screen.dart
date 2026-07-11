import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:smartbunda/models/assessment_catalog.dart';
import 'package:smartbunda/models/assessment_result.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/theme/app_spacing.dart';
import 'package:smartbunda/theme/app_theme.dart';

/// Step 4–7 of the assessment flow: show the result, **Save** (mandatory),
/// and optionally Share / Download PDF. Save is the primary action and the
/// user is warned if they try to leave without saving.
class AssessmentResultScreen extends ConsumerStatefulWidget {
  const AssessmentResultScreen({
    super.key,
    required this.assessment,
    required this.result,
    this.alreadySaved = false,
  });

  final Assessment assessment;
  final AssessmentResult result;

  /// True when opened from History (a previously-saved result) — Save is hidden.
  final bool alreadySaved;

  @override
  ConsumerState<AssessmentResultScreen> createState() =>
      _AssessmentResultScreenState();
}

class _AssessmentResultScreenState
    extends ConsumerState<AssessmentResultScreen> {
  late bool _saved = widget.alreadySaved;
  bool _saving = false;

  AssessmentResult get _r => widget.result;

  Color _bandColor(BuildContext context) {
    final semantic = Theme.of(context).extension<SmartBundaColors>()!;
    return switch (_r.band) {
      RiskBand.low => semantic.success,
      RiskBand.moderate => semantic.warning,
      RiskBand.high => Theme.of(context).colorScheme.error,
    };
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _toast('Please sign in to save your result.');
      return;
    }
    setState(() => _saving = true);
    try {
      // Stamp the owner now that we know the signed-in patient.
      final toSave = AssessmentResult(
        id: _r.id,
        patientId: user.id,
        assessmentId: _r.assessmentId,
        assessmentTitle: _r.assessmentTitle,
        version: _r.version,
        score: _r.score,
        maxScore: _r.maxScore,
        band: _r.band,
        summary: _r.summary,
        recommendations: _r.recommendations,
        answers: _r.answers,
        completedAt: _r.completedAt,
      );
      await ref.read(assessmentResultRepositoryProvider).save(toSave);
      if (!mounted) return;
      setState(() => _saved = true);
      _toast('Assessment result saved to your medical records.');
    } catch (e) {
      if (!mounted) return;
      _toast('Could not save result: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmLeave() async {
    if (_saved) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text(
          'Your assessment result has not been saved yet and will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep result'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = _bandColor(context);
    final dateLabel =
        DateFormat('d MMM yyyy, h:mm a').format(_r.completedAt);

    return PopScope(
      canPop: _saved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Assessment Result')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.xl),
          children: [
            // ── Risk band hero ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.brL,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Icon(_r.band.icon, color: color, size: 48),
                  const SizedBox(height: AppSpacing.s),
                  Text(_r.band.label,
                      style: text.headlineSmall?.copyWith(color: color)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Score ${_r.score} of ${_r.maxScore}',
                      style: text.labelLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // ── Meta ──────────────────────────────────────────────────────
            SbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metaRow('Assessment', widget.assessment.title),
                  _metaRow('Date & time', dateLabel),
                  _metaRow('Risk category', _r.band.label),
                  _metaRow('Risk score', '${_r.score} / ${_r.maxScore}'),
                  _metaRow('Version', 'v${_r.version}', last: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // ── Summary ───────────────────────────────────────────────────
            Text('Summary', style: text.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Text(_r.summary, style: text.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.m),

            // ── Recommendations ───────────────────────────────────────────
            Text('Recommendations', style: text.titleMedium),
            const SizedBox(height: AppSpacing.s),
            for (final rec in _r.recommendations)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 20, color: scheme.primary),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(rec,
                          style: text.bodyMedium?.copyWith(height: 1.45)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.m),

            _disclaimerBanner(context),
            const SizedBox(height: AppSpacing.l),

            // ── Actions ───────────────────────────────────────────────────
            if (!_saved)
              SbLoadingButton(
                label: 'Save Result',
                icon: Icons.save_outlined,
                loading: _saving,
                onPressed: _save,
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: _bandColorSaved(context)),
                  const SizedBox(width: AppSpacing.s),
                  Text('Saved to medical records',
                      style: text.labelLarge),
                ],
              ),
            const SizedBox(height: AppSpacing.s + 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s + 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            if (_saved) ...[
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _bandColorSaved(BuildContext context) =>
      Theme.of(context).extension<SmartBundaColors>()!.success;

  Widget _metaRow(String label, String value, {bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: text.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── PDF ─────────────────────────────────────────────────────────────────
  Future<File> _buildPdfFile() async {
    final pdf = pw.Document();
    final dateStr =
        DateFormat('d MMM yyyy, h:mm a').format(_r.completedAt);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SmartBunda — ${widget.assessment.title}',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFFD96C8A))),
          ),
          pw.Paragraph(text: 'Date: $dateStr'),
          pw.Paragraph(
              text:
                  'Risk category: ${_r.band.label}   (score ${_r.score} of ${_r.maxScore})'),
          pw.SizedBox(height: 8),
          pw.Header(level: 1, text: 'Summary'),
          pw.Paragraph(text: _r.summary),
          pw.Header(level: 1, text: 'Recommendations'),
          for (final rec in _r.recommendations)
            pw.Bullet(text: rec),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border:
                  pw.Border.all(color: const PdfColor.fromInt(0xFFF57C00)),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'This is a screening questionnaire, not a medical diagnosis. '
              'Always consult a qualified healthcare professional.',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF6D4C00)),
            ),
          ),
        ],
      ),
    );
    final fileName =
        '${_r.assessmentId}_${DateFormat('yyyyMMdd_HHmmss').format(_r.completedAt)}.pdf';
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _downloadPdf() async {
    try {
      final file = await _buildPdfFile();
      if (!mounted) return;
      _toast('PDF saved: ${file.path.split(Platform.pathSeparator).last}');
    } catch (e) {
      if (!mounted) return;
      _toast('Could not create PDF: $e');
    }
  }

  Future<void> _sharePdf() async {
    try {
      final file = await _buildPdfFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'SmartBunda — ${widget.assessment.title}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Could not share PDF: $e');
    }
  }
}

Widget _disclaimerBanner(BuildContext context) {
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ),
      ],
    ),
  );
}
