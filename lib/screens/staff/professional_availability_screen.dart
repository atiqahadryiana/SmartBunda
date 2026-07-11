/// SmartBunda — Consultation Availability & Session Schedule
///
/// Lets a healthcare professional mark the SPECIFIC DATES they are available
/// for consultations and, for each date, which session slots (Morning /
/// Afternoon / Evening). Persisted to the user document via `saveUserSettings`
/// under the `availability` key as `{ "yyyy-MM-dd": ["Morning", ...] }`, and
/// restored on open via `loadUserSettings`.
library smartbunda.professional_availability_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';

const _slots = ['Morning', 'Afternoon', 'Evening'];

class ProfessionalAvailabilityScreen extends ConsumerStatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  ConsumerState<ProfessionalAvailabilityScreen> createState() =>
      _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState
    extends ConsumerState<ProfessionalAvailabilityScreen> {
  /// Blocked/unavailable dates. The professional is available by default; each
  /// entry here marks a date OFF. The value is the set of session slots blocked
  /// on that date — an EMPTY set means the WHOLE day is unavailable.
  final Map<DateTime, Set<String>> _unavailable = {};
  String _defaultType = 'Consultation';
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final settings =
          await ref.read(authRepositoryProvider).loadUserSettings(user.id);
      final raw = settings['unavailableDates'];
      final loaded = <DateTime, Set<String>>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          final date = DateTime.tryParse('$key');
          if (date == null) return;
          // A list of blocked slots, or anything else → whole day off.
          loaded[_dateOnly(date)] = value is List
              ? value.map((e) => '$e').where(_slots.contains).toSet()
              : <String>{};
        });
      }
      final type = settings['defaultAppointmentType'];
      if (!mounted) return;
      setState(() {
        _unavailable
          ..clear()
          ..addAll(loaded);
        if (type is String && type.isNotEmpty) _defaultType = type;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: _dateOnly(now),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select a date you are unavailable',
    );
    if (picked == null) return;
    setState(() {
      // A newly blocked date defaults to the WHOLE day off (empty slot set).
      _unavailable.putIfAbsent(_dateOnly(picked), () => <String>{});
    });
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).saveUserSettings(
        userId: user.id,
        settings: {
          // Map of blocked dates → list of blocked slots (empty = whole day).
          'unavailableDates': {
            for (final entry in _unavailable.entries)
              _key(entry.key): entry.value.toList(),
          },
          'defaultAppointmentType': _defaultType,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('Availability saved.'))),
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.t('Save failed')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final dates = _unavailable.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Consultation Availability'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  strings.t('Unavailable Dates'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t(
                      'You are available by default. Mark the dates you are OFF — block the whole day or just specific sessions.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addDate,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(strings.t('Mark a date unavailable')),
                ),
                const SizedBox(height: 12),
                if (dates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        strings.t('Available on all dates — none blocked.'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  for (final date in dates) _dateRow(date, strings),
                const SizedBox(height: 20),
                Text(
                  strings.t('Appointment Preferences'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _defaultType,
                      decoration: InputDecoration(
                        labelText: strings.t('Default appointment type'),
                        border: InputBorder.none,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Consultation', child: Text('Consultation')),
                        DropdownMenuItem(
                            value: 'Follow Up', child: Text('Follow Up')),
                        DropdownMenuItem(
                            value: 'Nutrition Review',
                            child: Text('Nutrition Review')),
                        DropdownMenuItem(
                            value: 'Pregnancy Monitoring',
                            child: Text('Pregnancy Monitoring')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _defaultType = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.t('Save Availability')),
                ),
              ],
            ),
    );
  }

  Widget _dateRow(DateTime date, AppStrings strings) {
    // Blocked slots for this date; empty set = whole day unavailable.
    final blocked = _unavailable[date] ?? <String>{};
    final wholeDay = blocked.isEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateLabel(date),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: strings.t('Remove'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _unavailable.remove(date)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              wholeDay
                  ? strings.t('Whole day unavailable')
                  : strings.t('Some sessions blocked'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('Block only specific sessions (optional):'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final slot in _slots)
                  FilterChip(
                    label: Text(strings.t(slot)),
                    selected: blocked.contains(slot),
                    selectedColor: scheme.error.withValues(alpha: 0.18),
                    checkmarkColor: scheme.error,
                    onSelected: (selected) {
                      setState(() {
                        final set = _unavailable.putIfAbsent(date, () => {});
                        if (selected) {
                          set.add(slot);
                        } else {
                          set.remove(slot);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (!wholeDay) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _unavailable[date] = <String>{}),
                icon: const Icon(Icons.block, size: 16),
                label: Text(strings.t('Block whole day')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _dateLabel(DateTime d) {
    final weekday = _weekdayNames[d.weekday - 1];
    final month = _monthNames[d.month - 1];
    return '$weekday, $month ${d.day}, ${d.year}';
  }
}
