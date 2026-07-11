import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/models/assessment_catalog.dart';
import 'package:smartbunda/models/assessment_result.dart';
import 'package:smartbunda/models/clinical_note.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/screens/assessment/assessment_list_screen.dart';
import 'package:smartbunda/screens/assessment/assessment_result_screen.dart';
import 'package:smartbunda/screens/staff/add_clinical_note_screen.dart';
import 'package:smartbunda/theme/app_components.dart';

/// Medical Records only — clinical history (assessments, care notes, and
/// past appointment/visit records). Daily lifestyle logs (meals, hydration,
/// food scans) live in the Log tab, not here.
enum HistoryFilter {
  all,
  assessments,
  notes,
  appointments,
}

const historyFilterMeta = {
  HistoryFilter.all: _FilterMeta('All', Icons.folder_outlined),
  HistoryFilter.assessments: _FilterMeta('Assessments', Icons.assessment),
  HistoryFilter.notes: _FilterMeta('Care Notes', Icons.medical_information),
  HistoryFilter.appointments: _FilterMeta('Visits', Icons.calendar_today),
};

class _FilterMeta {
  const _FilterMeta(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  final String id;
  final HistoryFilter type;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final DateTime date;

  /// Optional handler — when set the timeline card is tappable (e.g. open a
  /// saved assessment result).
  final VoidCallback? onTap;
}

class HealthRecordScreen extends ConsumerStatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  ConsumerState<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends ConsumerState<HealthRecordScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Medical records only: clinical assessments, healthcare-professional
    // notes, and past appointment/visit records.
    final appointments = ref.watch(appointmentsProvider).valueOrNull ?? const <Appointment>[];
    final assessments =
        ref.watch(assessmentResultsProvider).valueOrNull ?? const <AssessmentResult>[];
    final notes =
        ref.watch(clinicalNotesProvider).valueOrNull ?? const <ClinicalNote>[];

    final events = _buildEvents(appointments, assessments, notes);
    final hasAnyRecords = events.isNotEmpty;
    final byFilter = _selectedFilter == HistoryFilter.all
        ? events
        : events.where((e) => e.type == _selectedFilter).toList();
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? byFilter
        : byFilter.where((e) {
            final hay =
                '${e.title} ${e.subtitle ?? ''}'.toLowerCase();
            return hay.contains(query);
          }).toList();
    final grouped = _groupEvents(filtered);

    return Scaffold(
      body: Column(
        children: [
          SbHeaderBanner(
            title: 'Medical Records',
            subtitle: 'Assessments, care notes & visits',
            icon: Icons.folder_shared_outlined,
            action: IconButton.filledTonal(
              tooltip: 'Digital Assessments',
              icon: const Icon(Icons.assignment_outlined),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.6),
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AssessmentListScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
          ),
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
          Expanded(
            child: filtered.isEmpty
                ? (hasAnyRecords
                    ? _EmptyState(
                        filter: historyFilterMeta[_selectedFilter]!.label)
                    : _NoRecordsState(
                        onStartAssessment: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AssessmentListScreen(),
                          ),
                        ),
                      ))
                : _TimelineView(grouped: grouped),
          ),
        ],
      ),
    );
  }

  List<_TimelineEvent> _buildEvents(
    List<Appointment> appointments,
    List<AssessmentResult> assessments,
    List<ClinicalNote> notes,
  ) {
    final events = <_TimelineEvent>[];

    for (final note in notes) {
      events.add(_TimelineEvent(
        id: 'note-${note.id}',
        type: HistoryFilter.notes,
        title: 'Note from ${note.professionalName}',
        subtitle: note.clinicalNote,
        icon: Icons.medical_information,
        color: const Color(0xFF2A9D9A),
        date: note.createdAt,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SingleChildScrollView(child: ClinicalNoteCard(note: note)),
          ),
        ),
      ));
    }

    for (final result in assessments) {
      events.add(_TimelineEvent(
        id: 'assess-${result.id}',
        type: HistoryFilter.assessments,
        title: result.assessmentTitle,
        subtitle:
            '${result.band.label}  |  Score ${result.score}/${result.maxScore}',
        icon: Icons.assessment,
        color: const Color(0xFF7B61FF),
        date: result.completedAt,
        onTap: () {
          final assessment = AssessmentCatalog.byId(result.assessmentId);
          if (assessment == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AssessmentResultScreen(
                assessment: assessment,
                result: result,
                alreadySaved: true,
              ),
            ),
          );
        },
      ));
    }

    for (final apt in appointments) {
      events.add(_TimelineEvent(
        id: 'apt-${apt.id}',
        type: HistoryFilter.appointments,
        title: apt.type,
        subtitle: 'Status: ${apt.status}  |  ${DateFormat('h:mm a').format(apt.dateTime)}',
        icon: Icons.calendar_today,
        color: const Color(0xFFFF9800),
        date: apt.dateTime,
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  Map<String, List<_TimelineEvent>> _groupEvents(List<_TimelineEvent> events) {
    final groups = <String, List<_TimelineEvent>>{};
    final now = DateTime.now();
    for (final event in events) {
      final group = _groupTitleFor(event.date, now);
      groups.putIfAbsent(group, () => []).add(event);
    }
    const order = ['Today', 'Yesterday', 'This Week', 'This Month', 'Older'];
    return {
      for (final key in order)
        if (groups[key] != null) key: groups[key]!,
    };
  }
}

String _groupTitleFor(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(date.year, date.month, date.day);
  final diff = today.difference(eventDay).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'This Week';
  if (date.year == now.year && date.month == now.month) return 'This Month';
  return 'Older';
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: HistoryFilter.values.map((filter) {
            final meta = historyFilterMeta[filter]!;
            final isSelected = filter == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(meta.label),
                selected: isSelected,
                avatar: Icon(meta.icon, size: 18),
                onSelected: (_) => onChanged(filter),
                selectedColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No $filter entries yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Start logging to see your history here.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.grouped});
  final Map<String, List<_TimelineEvent>> grouped;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final entry in grouped.entries) ...[
          _DateSectionHeader(title: entry.key),
          const SizedBox(height: 8),
          for (final event in entry.value) ...[
            _TimelineCard(event: event),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
      ),
    );
  }
}



class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.event});
  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = event.color ?? scheme.primary;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.039),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.071),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(event.icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (event.onTap != null)
            Icon(Icons.chevron_right_rounded, color: scheme.outline)
          else
            Text(
              DateFormat('h:mm a').format(event.date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );

    if (event.onTap == null) return card;
    return Semantics(
      button: true,
      label: '${event.title}. ${event.subtitle ?? ''}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: event.onTap,
          borderRadius: BorderRadius.circular(18),
          child: card,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search records, assessments, professionals…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Spec empty state: shown when the patient has no medical records at all.
class _NoRecordsState extends StatelessWidget {
  const _NoRecordsState({required this.onStartAssessment});
  final VoidCallback onStartAssessment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('No medical records yet',
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your medical records will appear here once you complete '
              'assessments, attend appointments, or your care team adds notes.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStartAssessment,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}


