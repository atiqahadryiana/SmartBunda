/// SmartBunda — Consultation Availability & Session Schedule
///
/// Lets a healthcare professional set which session slots they are available
/// for on each weekday, plus default appointment preferences. Persisted to the
/// user document via `saveUserSettings` under the `availability` key.
library smartbunda.professional_availability_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../theme/app_theme.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _slots = ['Morning', 'Afternoon', 'Evening'];

class ProfessionalAvailabilityScreen extends ConsumerStatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  ConsumerState<ProfessionalAvailabilityScreen> createState() =>
      _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState
    extends ConsumerState<ProfessionalAvailabilityScreen> {
  // weekday -> set of enabled slots
  final Map<String, Set<String>> _availability = {
    for (final day in _weekdays.take(5)) day: {'Morning', 'Afternoon'},
  };
  String _defaultType = 'Consultation';
  bool _saving = false;

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).saveUserSettings(
        userId: user.id,
        settings: {
          'availability': {
            for (final entry in _availability.entries)
              entry.key: entry.value.toList(),
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
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Consultation Availability'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            strings.t('Session Schedule'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            strings.t('Choose the session slots you are available each day.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final day in _weekdays) _dayRow(day, strings),
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

  Widget _dayRow(String day, AppStrings strings) {
    final enabled = _availability[day] ?? <String>{};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t(day),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final slot in _slots)
                  FilterChip(
                    label: Text(strings.t(slot)),
                    selected: enabled.contains(slot),
                    selectedColor: AppTheme.primaryPink.withValues(alpha: 70),
                    onSelected: (selected) {
                      setState(() {
                        final set = _availability.putIfAbsent(day, () => {});
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
          ],
        ),
      ),
    );
  }
}
