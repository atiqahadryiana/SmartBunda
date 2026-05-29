import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart' as printing;

import '../localization/app_strings.dart';
import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../models/firestore_doc.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/report_pdf_service.dart';
import '../services/service_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/empty_state.dart';
import '../widgets/report_preview_widget.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final user = ref.watch(currentUserProvider);
    final effectiveRole = user?.role ?? role;
    final view = effectiveRole == UserRole.admin
        ? _AdminAnalyticsView(showAppBar: showAppBar)
        : effectiveRole == UserRole.patient
            ? _PatientReportView(showAppBar: showAppBar)
            : _ClinicianReportView(showAppBar: showAppBar);
    return RequireSignIn(
      title: strings.t('Reports'),
      showAppBar: showAppBar,
      message: strings.t('Please sign in to view reports.'),
      child: view,
    );
  }
}

class _PatientReportView extends ConsumerStatefulWidget {
  const _PatientReportView({required this.showAppBar});

  final bool showAppBar;

  @override
  ConsumerState<_PatientReportView> createState() =>
      _PatientReportViewState();
}

class _PatientReportViewState extends ConsumerState<_PatientReportView> {
  List<int>? _pdfBytes;
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final strings = AppStrings.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.t('Reports'))) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: entriesAsync.when(
          data: (entries) {
            final pregnancy = pregnancyAsync.valueOrNull;
            final summary = _weeklySummary(entries);
            final targets = _targets(pregnancy);
            final caloriePct = targets.calories == 0
                ? 0
                : (summary.calories / targets.calories * 100);
            final proteinPct = targets.protein == 0
                ? 0
                : (summary.protein / targets.protein * 100);
            return ListView(
              children: [
                ScreenHeader(
                  title: strings.t('Weekly report'),
                  subtitle: strings.t(
                      'Track your average intake and progress over the last 7 days.'),
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Average intake')),
                    subtitle: Text(
                      '${summary.calories} kcal | ${summary.protein} g protein',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Target adherence')),
                    subtitle: Text(
                      '${caloriePct.toStringAsFixed(0)}% calories, '
                      '${proteinPct.toStringAsFixed(0)}% protein',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── PDF Preview Section ────────────────────────────────
                ReportTitleSection(
                  title: strings.t('Download Report'),
                  subtitle: strings.t('Generate and download your weekly nutrition report as PDF.'),
                ),
                const SizedBox(height: 12),
                ReportMetadataGrid(
                  category: 'Medical Report',
                  status: 'Completed',
                  preparedBy: 'SMARTBUNDA Care Team',
                  date: DateFormat('d MMM yyyy').format(DateTime.now()),
                ),
                const SizedBox(height: 14),
                PDFPreviewSection(
                  pdfUrl: _pdfBytes != null ? 'generated' : null,
                  onOpen: _pdfBytes != null
                      ? () async {
                          await printing.Printing.sharePdf(
                            bytes: Uint8List.fromList(_pdfBytes!),
                            filename:
                                'nutrition-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
                          );
                        }
                      : null,
                  onDownload: _pdfBytes != null
                      ? () async {
                          await printing.Printing.sharePdf(
                            bytes: Uint8List.fromList(_pdfBytes!),
                            filename:
                                'nutrition-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
                          );
                        }
                      : null,
                  onShare: _pdfBytes != null
                      ? () async {
                          await printing.Printing.sharePdf(
                            bytes: Uint8List.fromList(_pdfBytes!),
                            filename:
                                'nutrition-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _generatingPdf
                      ? null
                      : () => _generateAndSavePdf(
                            context,
                            ref,
                            user,
                            entries,
                            summary,
                            targets,
                          ),
                  icon: _generatingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_generatingPdf
                      ? strings.t('Generating...')
                      : strings.t('Generate PDF')),
                ),
                const SizedBox(height: 16),
                MedicalDisclaimerBanner(),
                const SizedBox(height: 16),
                Text(
                  strings.t('Saved reports'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                reportsAsync.when(
                  data: (reports) {
                    if (reports.isEmpty) {
                      return Text(strings.t('No saved reports yet.'));
                    }
                    return Column(
                      children: reports
                          .map((doc) => _reportTile(context, doc))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(strings.errorLoadingReports('$e')),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  _EntryTotals _weeklySummary(List<FoodEntry> entries) {
    final now = DateTime.now();
    final recent =
        entries.where((entry) => now.difference(entry.date).inDays <= 7);
    if (recent.isEmpty) {
      return _EntryTotals(calories: 0, protein: 0);
    }
    final totalCalories = recent.fold<int>(0, (sum, e) => sum + e.calories);
    final totalProtein = recent.fold<int>(0, (sum, e) => sum + e.protein);
    final days = recent.map((e) => _dayKey(e.date)).toSet().length;
    return _EntryTotals(
      calories: (totalCalories / days).round(),
      protein: (totalProtein / days).round(),
    );
  }

  _Targets _targets(Pregnancy? pregnancy) {
    final defaults = recommendedFor(pregnancy);
    return _Targets(
      calories: defaults.calories,
      protein: defaults.protein,
    );
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  Widget _reportTile(BuildContext context, FirestoreDoc doc) {
    final strings = AppStrings.of(context);
    final createdAt = doc.timestamp;
    final createdLabel = createdAt == null
        ? strings.t('Saved report')
        : strings.savedAtLabel(createdAt.toLocal());
    final calories = doc.data['avgCalories'];
    final protein = doc.data['avgProtein'];
    final summary = [
      if (calories != null) '${strings.t('Calories')}: $calories',
      if (protein != null) '${strings.t('Protein')}: $protein',
    ].join(' | ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assessment_outlined),
        title: Text(doc.title ?? createdLabel),
        subtitle: summary.isEmpty
            ? Text(createdLabel)
            : Text('$createdLabel | $summary'),
      ),
    );
  }

  Future<void> _generateAndSavePdf(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    List<FoodEntry> entries,
    _EntryTotals summary,
    _Targets targets,
  ) async {
    if (user == null) return;

    setState(() => _generatingPdf = true);

    try {
      final pdfBytes = await ReportPdfService.generateReportPdf(
        ReportPdfData(
          patientName: user.displayName ?? 'User',
          reportDate: DateFormat('d MMM yyyy').format(DateTime.now()),
          avgCalories: summary.calories,
          calorieTarget: targets.calories,
          avgProtein: summary.protein,
          proteinTarget: targets.protein,
          recentEntries: entries.where((e) {
            return DateTime.now().difference(e.date).inDays <= 7;
          }).toList(),
        ),
      );

      if (mounted) {
        setState(() => _pdfBytes = pdfBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      setState(() => _generatingPdf = false);
    }
  }
}

class _ClinicianReportView extends ConsumerWidget {
  const _ClinicianReportView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final usersAsync = ref.watch(usersProvider);
    final entriesAsync = ref.watch(allEntriesProvider);
    final pregnanciesAsync = ref.watch(allPregnanciesProvider);
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.t('Reports'))) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: usersAsync.when(
          data: (users) {
            final patients =
                users.where((u) => u.role == UserRole.patient).toList();
            final entriesByUser = entriesAsync.valueOrNull ?? {};
            final pregnancies = pregnanciesAsync.valueOrNull ?? {};
            final profiles = profilesAsync.valueOrNull ?? {};
            if (patients.isEmpty) {
              return EmptyState(
                icon: Icons.assessment_outlined,
                title: strings.t('No patient reports yet'),
                message: strings.t(
                    'Reports will appear once patients start logging meals.'),
              );
            }
            return ListView(
              children: [
                ScreenHeader(
                  title: strings.t('Reports overview'),
                  subtitle: strings.t(
                      'Tap a patient to review their last 7 days of intake.'),
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final entries =
                        entriesByUser[patient.id] ?? const <FoodEntry>[];
                    final pregnancy = pregnancies[patient.id];
                    final profile = profiles[patient.id];
                    final compliance = _compliance(entries, pregnancy);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assessment_outlined),
                        title: Text(patient.displayName ?? patient.email),
                        subtitle: Text(
                          [
                            strings.complianceLast7Days(
                                compliance.toStringAsFixed(0)),
                            if (pregnancy != null)
                              '${strings.week}: ${pregnancy.gestationalWeek}',
                            if (profile != null)
                              '${strings.weight}: ${profile.currentWeightKg.toStringAsFixed(1)} kg',
                          ].join(' | '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPatientReport(
                          context,
                          patient,
                          entries,
                          pregnancy,
                          profile,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  double _compliance(List<FoodEntry> entries, Pregnancy? pregnancy) {
    if (entries.isEmpty) return 0;
    final now = DateTime.now();
    final recent =
        entries.where((e) => now.difference(e.date).inDays <= 7).toList();
    if (recent.isEmpty) return 0;
    final targets = recommendedFor(pregnancy);
    final calorieTarget = targets.calories;
    final byDay = <String, int>{};
    for (final entry in recent) {
      final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      byDay[key] = (byDay[key] ?? 0) + entry.calories;
    }
    final onTrackDays =
        byDay.values.where((cal) => cal >= calorieTarget * 0.8).length;
    return byDay.isEmpty ? 0 : (onTrackDays / byDay.length * 100);
  }

  void _showPatientReport(
    BuildContext context,
    AppUser patient,
    List<FoodEntry> entries,
    Pregnancy? pregnancy,
    Profile? profile,
  ) {
    final strings = AppStrings.of(context);
    final totals = entries.fold<int>(0, (sum, e) => sum + e.calories);
    final count = entries.length;
    final targets = recommendedFor(pregnancy);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.reportFor(patient.displayName ?? patient.email)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('Medical report'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _ReportRow(
                label: strings.gestationalWeek,
                value: pregnancy == null
                    ? '--'
                    : pregnancy.gestationalWeek.toString(),
              ),
              _ReportRow(
                label: strings.weight,
                value: _measurement(profile?.currentWeightKg, 'kg'),
              ),
              _ReportRow(
                label: strings.hemoglobin,
                value: _measurement(profile?.hemoglobinGdl, 'g/dL'),
              ),
              _ReportRow(
                label: strings.abdominalCircumference,
                value: _measurement(profile?.abdominalCircumferenceCm, 'cm'),
              ),
              const SizedBox(height: 12),
              Text(
                strings.t('Nutrition report'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.entriesLogged(count)),
              Text(strings.totalCaloriesLogged(totals)),
              const SizedBox(height: 8),
              Text(strings.targetsSummary(targets.calories, targets.protein)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(strings.t('Close')),
          ),
        ],
      ),
    );
  }
}

class _AdminAnalyticsView extends ConsumerWidget {
  const _AdminAnalyticsView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final usersAsync = ref.watch(usersProvider);
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.t('Analytics'))) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: usersAsync.when(
          data: (users) {
            final active = users.where((u) => u.isActive).length;
            final inactive = users.length - active;
            final logins = logsAsync.valueOrNull
                    ?.where((log) => log.type == ActivityType.login)
                    .length ??
                0;
            return ListView(
              children: [
                ScreenHeader(
                  title: strings.t('System usage'),
                  subtitle: strings.t('High-level metrics across all users.'),
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Total users')),
                    trailing: Text('${users.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Active accounts')),
                    trailing: Text('$active'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Inactive accounts')),
                    trailing: Text('$inactive'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(strings.t('Total logins')),
                    trailing: Text('$logins'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _EntryTotals {
  _EntryTotals({required this.calories, required this.protein});
  final int calories;
  final int protein;
}

class _Targets {
  _Targets({required this.calories, required this.protein});
  final int calories;
  final int protein;
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _measurement(double? value, String unit) {
  if (value == null || value <= 0) return '--';
  return '${value.toStringAsFixed(1)} $unit';
}
