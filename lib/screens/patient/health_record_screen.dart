import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';

class HealthRecordScreen extends ConsumerWidget {
  const HealthRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final pregnancy = ref.watch(pregnancyProvider).valueOrNull;
    final entries =
        ref.watch(entriesProvider).valueOrNull ?? const <FoodEntry>[];
    final reports =
        ref.watch(reportsProvider).valueOrNull ?? const <FirestoreDoc>[];
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Health Record'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Medical History'),
              Tab(text: 'Vital Signs'),
              Tab(text: 'Nutrition'),
              Tab(text: 'Reports'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(profile: profile, week: pregnancy?.gestationalWeek),
            _ListTab(
              title: 'Medical History',
              icon: Icons.medical_information_outlined,
              items: [
                _RecordLine('Previous diagnoses', _conditions(profile)),
                const _RecordLine('Allergies', 'No allergies reported'),
                const _RecordLine('Medications', 'No medication added'),
                const _RecordLine('Chronic conditions', 'None reported'),
              ],
            ),
            const _ListTab(
              title: 'Vital Signs',
              icon: Icons.monitor_heart_outlined,
              items: [
                _RecordLine('Blood pressure', '118/76 mmHg'),
                _RecordLine('Heart rate', '78 bpm'),
                _RecordLine('Blood sugar', '5.2 mmol/L'),
                _RecordLine('Temperature', '36.8 C'),
                _RecordLine('Oxygen level', '98%'),
              ],
            ),
            _NutritionTab(entries: entries),
            _ReportsTab(reports: reports),
            _ProgressTab(entries: entries),
          ],
        ),
      ),
    );
  }

  String _conditions(Profile? profile) {
    if (profile == null || profile.medicalConditions.isEmpty) {
      return 'None reported';
    }
    return profile.medicalConditions.map((item) => item.name).join(', ');
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.profile, required this.week});
  final Profile? profile;
  final int? week;

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi(profile);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _RecordHero(
          title: 'Overall health summary',
          subtitle: 'A clear view of your current pregnancy health profile.',
          icon: Icons.health_and_safety_outlined,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _InsightCard(
                label: 'BMI', value: bmi ?? '--', icon: Icons.straighten),
            _InsightCard(
                label: 'Weight',
                value: profile == null
                    ? '--'
                    : '${profile!.currentWeightKg.toStringAsFixed(1)} kg',
                icon: Icons.monitor_weight_outlined),
            const _InsightCard(
              label: 'Blood pressure',
              value: '118/76',
              icon: Icons.favorite_outline,
            ),
            _InsightCard(
                label: 'Week',
                value: week?.toString() ?? '--',
                icon: Icons.pregnant_woman_outlined),
          ],
        ),
        const SizedBox(height: 16),
        const _NotesCard(),
      ],
    );
  }

  String? _bmi(Profile? profile) {
    if (profile == null ||
        profile.heightCm <= 0 ||
        profile.currentWeightKg <= 0) {
      return null;
    }
    final h = profile.heightCm / 100;
    return (profile.currentWeightKg / (h * h)).toStringAsFixed(1);
  }
}

class _NutritionTab extends StatelessWidget {
  const _NutritionTab({required this.entries});
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final calories = entries.fold<int>(0, (sum, item) => sum + item.calories);
    final protein = entries.fold<int>(0, (sum, item) => sum + item.protein);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _RecordHero(
          title: 'Nutrition History',
          subtitle:
              'Review calorie intake, meal records, and nutrition analysis.',
          icon: Icons.restaurant_menu,
        ),
        const SizedBox(height: 16),
        _RecordLine('Total meal logs', '${entries.length} records'),
        _RecordLine('Calories logged', '$calories kcal'),
        _RecordLine('Protein logged', '$protein g'),
        const _RecordLine(
            'Analysis', 'Keep logging meals for stronger insights'),
        const SizedBox(height: 12),
        ...entries.take(10).map((entry) => _MealRecord(entry: entry)),
      ],
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.entries});
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(7).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _RecordHero(
          title: 'Progress',
          subtitle: 'Simple trend views for weight, hydration, and nutrition.',
          icon: Icons.show_chart,
        ),
        const SizedBox(height: 16),
        _TrendCard(
            values: recent.map((entry) => entry.calories.toDouble()).toList()),
        const SizedBox(height: 12),
        const _RecordLine(
            'Weight tracking', 'Connect profile updates to view trends'),
        const _RecordLine(
            'Hydration trends', 'Track water daily to build a weekly chart'),
      ],
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab(
      {required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RecordHero(
            title: title,
            subtitle: 'Organized information for quick review.',
            icon: icon),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({required this.reports});

  final List<FirestoreDoc> reports;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  @override
  Widget build(BuildContext context) {
    final reports = _reportsFromDocs(widget.reports);
    final grouped = _groupReports(reports);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _RecordHero(
          title: 'Medical Reports',
          subtitle:
              'View, download, and share reports prepared by your care team.',
          icon: Icons.picture_as_pdf_outlined,
        ),
        const SizedBox(height: 16),
        if (reports.isEmpty)
          const _ReportsEmptyState()
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(reports.length),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in grouped.entries) ...[
                  _DateSectionHeader(title: entry.key),
                  const SizedBox(height: 10),
                  for (final report in entry.value) ...[
                    _ReportCard(
                      report: report,
                      onView: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ReportDetailScreen(report: report),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Map<String, List<_HealthReport>> _groupReports(List<_HealthReport> reports) {
    final groups = <String, List<_HealthReport>>{};
    final now = DateTime.now();
    for (final report in reports) {
      final group = _groupTitleFor(report.date, now);
      groups.putIfAbsent(group, () => []).add(report);
    }
    const order = ['Today', 'This Week', 'This Month', 'Previous Records'];
    return {
      for (final key in order)
        if (groups[key] != null) key: groups[key]!,
    };
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ],
    );
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report, required this.onView});

  final _HealthReport report;
  final VoidCallback onView;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(widget.report.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE3EE), Color(0xFFE8FAF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFFC24879),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReportChip(
                          label: widget.report.category,
                          color: scheme.primary,
                        ),
                        _ReportChip(
                          label: widget.report.status,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.report.provider,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      DateFormat('d MMM yyyy, h:mm a')
                          .format(widget.report.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: widget.report.bookmarked ? 'Bookmarked' : 'Bookmark',
                onPressed: () {},
                icon: Icon(
                  widget.report.bookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: widget.onView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloading ? null : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_downloading ? 'Saving' : 'PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.report.title} saved for offline view.')),
    );
  }
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 42, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            'No reports found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reports prepared by your care team will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailScreen extends StatelessWidget {
  const _ReportDetailScreen({required this.report});

  final _HealthReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share option ready.')),
            ),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Download PDF',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${report.title} saved for offline view.')),
            ),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _RecordHero(
            title: report.title,
            subtitle: '${report.category} from ${report.provider}',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),
          _ReportInfoGrid(report: report),
          const SizedBox(height: 16),
          Container(
            height: 360,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: Center(
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 52),
                      const SizedBox(height: 14),
                      Text(
                        report.title,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PDF / image preview placeholder',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecordLine('Doctor notes', report.notes),
          _RecordLine('Attached files', report.fileName),
        ],
      ),
    );
  }
}

class _ReportInfoGrid extends StatelessWidget {
  const _ReportInfoGrid({required this.report});

  final _HealthReport report;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _InsightCard(
            label: 'Category',
            value: report.category,
            icon: Icons.category_outlined),
        _InsightCard(
            label: 'Status',
            value: report.status,
            icon: Icons.verified_outlined),
        _InsightCard(
            label: 'Provider',
            value: report.provider,
            icon: Icons.local_hospital_outlined),
        _InsightCard(
          label: 'Date',
          value: DateFormat('d MMM yyyy').format(report.date),
          icon: Icons.calendar_month_outlined,
        ),
      ],
    );
  }
}

class _RecordHero extends StatelessWidget {
  const _RecordHero(
      {required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFE3EE), Color(0xFFE8FAF8)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC24879), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        leading: const Icon(Icons.check_circle_outline),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard();

  @override
  Widget build(BuildContext context) {
    return const _RecordLine(
      'Latest medical notes',
      'No recent notes. Your care team updates will appear here.',
    );
  }
}

class _MealRecord extends StatelessWidget {
  const _MealRecord({required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_outlined),
        title: Text(entry.meal),
        subtitle: Text(
            '${entry.calories} kcal | P ${entry.protein}g | C ${entry.carbs}g | F ${entry.fat}g'),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calorie trend',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _TrendPainter(values),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC24879)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bg = Paint()
      ..color = const Color(0xFFE8D2DA)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bg);
    }
    if (values.length < 2) return;
    final maxValue = values
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity)
        .toDouble();
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxValue * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

const _reportCategories = [
  'Lab Results',
  'Prescriptions',
  'Blood Test',
  'X-Ray',
  'Ultrasound',
  'Vaccination',
  'Medical Certificate',
  'Nutrition Report',
];

class _HealthReport {
  const _HealthReport({
    required this.id,
    required this.title,
    required this.category,
    required this.provider,
    required this.date,
    required this.status,
    required this.notes,
    required this.fileName,
    this.bookmarked = false,
  });

  final String id;
  final String title;
  final String category;
  final String provider;
  final DateTime date;
  final String status;
  final String notes;
  final String fileName;
  final bool bookmarked;
}

List<_HealthReport> _reportsFromDocs(List<FirestoreDoc> docs) {
  if (docs.isEmpty) return _sampleReports();
  return docs.map(_reportFromDoc).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

_HealthReport _reportFromDoc(FirestoreDoc doc) {
  final data = doc.data;
  final category = _normalizeCategory(
    _string(data, ['category', 'reportCategory', 'type']) ?? 'Medical Report',
  );
  final provider = _string(
          data, ['doctor', 'doctorName', 'hospital', 'clinic', 'provider']) ??
      'SMARTBUNDA Care Team';
  final status = _normalizeStatus(_string(data, ['status']) ?? 'Completed');
  final date = doc.timestamp ??
      _date(data, ['reportDate', 'uploadedAt', 'dateTime', 'createdAt']) ??
      DateTime.now();
  final title = doc.title ??
      _string(data, ['reportTitle', 'fileName']) ??
      '$category - ${DateFormat('d MMM yyyy').format(date)}';
  final notes = _string(data, ['notes', 'doctorNotes', 'summary']) ??
      'No doctor notes attached.';
  final fileName =
      _string(data, ['fileName', 'pdfName', 'attachmentName']) ?? '$title.pdf';
  return _HealthReport(
    id: doc.id,
    title: title,
    category: category,
    provider: provider,
    date: date,
    status: status,
    notes: notes,
    fileName: fileName,
    bookmarked: data['bookmarked'] == true || data['favorite'] == true,
  );
}

List<_HealthReport> _sampleReports() {
  final now = DateTime.now();
  return [
    _HealthReport(
      id: 'sample-nutrition',
      title: 'Pregnancy Nutrition Review',
      category: 'Nutrition Report',
      provider: 'SMARTBUNDA Dietitian',
      date: now.subtract(const Duration(hours: 3)),
      status: 'Reviewed',
      notes: 'Protein intake is improving. Continue hydration tracking daily.',
      fileName: 'pregnancy_nutrition_review.pdf',
      bookmarked: true,
    ),
    _HealthReport(
      id: 'sample-blood',
      title: 'Hemoglobin Blood Test',
      category: 'Blood Test',
      provider: 'Klinik Sentosa',
      date: now.subtract(const Duration(days: 2)),
      status: 'Completed',
      notes: 'Hemoglobin results are available for care-team review.',
      fileName: 'hemoglobin_blood_test.pdf',
    ),
    _HealthReport(
      id: 'sample-ultrasound',
      title: 'Second Trimester Ultrasound',
      category: 'Ultrasound',
      provider: 'Hospital Wanita Kuala Lumpur',
      date: now.subtract(const Duration(days: 12)),
      status: 'Completed',
      notes: 'Routine scan uploaded. Follow the next appointment schedule.',
      fileName: 'trimester_ultrasound.pdf',
    ),
    _HealthReport(
      id: 'sample-prescription',
      title: 'Iron Supplement Prescription',
      category: 'Prescriptions',
      provider: 'Dr. Nur Aina',
      date: now.subtract(const Duration(days: 46)),
      status: 'Completed',
      notes: 'Prescription history saved for offline access.',
      fileName: 'iron_supplement_prescription.pdf',
    ),
  ];
}

String _groupTitleFor(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final recordDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(recordDay).inDays;
  if (days == 0) return 'Today';
  if (days >= 0 && days < 7) return 'This Week';
  if (date.year == now.year && date.month == now.month) return 'This Month';
  return 'Previous Records';
}

String? _string(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

DateTime? _date(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String _normalizeCategory(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return 'Medical Report';
  for (final category in _reportCategories) {
    if (category.toLowerCase() == cleaned.toLowerCase()) return category;
  }
  return cleaned
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _normalizeStatus(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return 'Completed';
  return cleaned
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const Color(0xFFF2A93B);
    case 'reviewed':
      return const Color(0xFF23A6A6);
    case 'completed':
      return const Color(0xFF4F8DF7);
    default:
      return const Color(0xFFC24879);
  }
}
