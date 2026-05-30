import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';
import 'package:smartbunda/screens/staff/nutritionist_client_screen.dart';

class NutritionistScreen extends ConsumerWidget {
  const NutritionistScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final allEntriesAsync = ref.watch(allEntriesProvider);
    final allProfilesAsync = ref.watch(allProfilesProvider);
    final allPregnanciesAsync = ref.watch(allPregnanciesProvider);

    return RequireSignIn(
      title: '${role.label} dashboard',
      showAppBar: showAppBar,
      message: 'Please sign in to view client analytics.',
      child: Scaffold(
        appBar:
            showAppBar ? AppBar(title: Text('${role.label} dashboard')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: usersAsync.when(
            data: (users) {
              final allEntries = allEntriesAsync.valueOrNull;
              final allProfiles = allProfilesAsync.valueOrNull;
              final allPregnancies = allPregnanciesAsync.valueOrNull;
              if (allEntries == null ||
                  allProfiles == null ||
                  allPregnancies == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final clients =
                  users.where((u) => u.role == UserRole.patient).toList();
              final today = DateTime.now();
              final summaries = clients.map((client) {
                final entries = allEntries[client.id] ?? const <FoodEntry>[];
                final profile = allProfiles[client.id];
                final pregnancy = allPregnancies[client.id];
                final todays =
                    entries.where((e) => _isSameDay(e.date, today)).toList();
                var lastLogged = entries.isEmpty ? null : entries.first.date;
                for (final entry in entries) {
                  if (lastLogged == null || entry.date.isAfter(lastLogged)) {
                    lastLogged = entry.date;
                  }
                }
                final calories =
                    todays.fold<int>(0, (sum, e) => sum + e.calories);
                return _ClientSummary(
                  user: client,
                  mealsToday: todays.length,
                  caloriesToday: calories,
                  lastLogged: lastLogged,
                  entries: entries,
                  profile: profile,
                  pregnancy: pregnancy,
                );
              }).toList();

              final totalMealsToday =
                  summaries.fold<int>(0, (sum, s) => sum + s.mealsToday);
              final active = summaries.where((s) => s.mealsToday > 0).toList();
              final avgCalories = active.isEmpty
                  ? 0
                  : (active.fold<int>(0, (sum, s) => sum + s.caloriesToday) /
                          active.length)
                      .round();
              final needsAttention = summaries
                  .where((s) => s.mealsToday == 0 || s.profile == null)
                  .toList();

              final recentLogs = <_LogItem>[];
              for (final summary in summaries) {
                for (final entry in summary.entries) {
                  recentLogs.add(_LogItem(entry: entry, user: summary.user));
                }
              }
              recentLogs.sort((a, b) => b.entry.date.compareTo(a.entry.date));

              return ListView(
                children: [
                  ScreenHeader(
                    title: '${role.label} dashboard',
                    subtitle: 'Monitor client activity and nutrition trends.',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        label: 'Active clients',
                        value: '${clients.length}',
                        icon: Icons.people_outline,
                      ),
                      _StatCard(
                        label: 'Meals today',
                        value: '$totalMealsToday',
                        icon: Icons.restaurant_menu,
                      ),
                      _StatCard(
                        label: 'Avg calories',
                        value: '$avgCalories kcal',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Clients needing attention',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (needsAttention.isEmpty)
                    const Text('All clients logged meals today.')
                  else
                    Card(
                      child: Column(
                        children: needsAttention
                            .take(5)
                            .map(
                              (summary) => ListTile(
                                leading:
                                    const Icon(Icons.warning_amber_outlined),
                                title: Text(
                                  summary.user.displayName ??
                                      summary.user.email,
                                ),
                                subtitle: Text(
                                  summary.profile == null
                                      ? 'Profile missing'
                                      : 'No meals logged today',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent logs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (recentLogs.isEmpty)
                    const Text('No meals logged yet.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentLogs.length > 6 ? 6 : recentLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = recentLogs[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant_menu_outlined),
                            title: Text(item.entry.meal),
                            subtitle: Text(
                              '${item.user.displayName ?? item.user.email}  -  ${item.entry.calories} kcal',
                            ),
                            trailing: Text(
                                '${item.entry.date.month}/${item.entry.date.day}'),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Client overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (summaries.isEmpty)
                    const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No clients registered yet',
                      message:
                          'Clients will appear here after they create accounts.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        final name =
                            summary.user.displayName ?? summary.user.email;
                        final lastLogged = summary.lastLogged == null
                            ? 'No logs yet'
                            : 'Last log ${summary.lastLogged!.month}/${summary.lastLogged!.day}';
                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(
                              '${summary.mealsToday} meals today  -  $lastLogged',
                            ),
                            trailing: Text('${summary.caloriesToday} kcal'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NutritionistClientScreen(
                                    client: summary.user,
                                    entries: summary.entries,
                                    profile: summary.profile,
                                    pregnancy: summary.pregnancy,
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientSummary {
  const _ClientSummary({
    required this.user,
    required this.mealsToday,
    required this.caloriesToday,
    required this.lastLogged,
    required this.entries,
    required this.profile,
    required this.pregnancy,
  });

  final AppUser user;
  final int mealsToday;
  final int caloriesToday;
  final DateTime? lastLogged;
  final List<FoodEntry> entries;
  final Profile? profile;
  final Pregnancy? pregnancy;
}

class _LogItem {
  const _LogItem({required this.entry, required this.user});

  final FoodEntry entry;
  final AppUser user;
}
