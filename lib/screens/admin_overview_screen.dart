import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    final usersAsync = ref.watch(usersProvider);

    return RequireSignIn(
      title: 'Overview',
      showAppBar: showAppBar,
      message: 'Please sign in to view the overview.',
      child: Scaffold(
        appBar: showAppBar ? AppBar(title: const Text('Overview')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: logsAsync.when(
            data: (logs) {
              final sorted = List.of(logs)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final users = usersAsync.valueOrNull ?? const <AppUser>[];
              final userById = {for (final u in users) u.id: u};
              final scheme = Theme.of(context).colorScheme;
              final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  );
              return ListView(
                children: [
                  const ScreenHeader(
                    title: 'Overview',
                    subtitle: 'Recent activity across the system.',
                    icon: Icons.dashboard_outlined,
                  ),
                  const SizedBox(height: 16),
                  if (sorted.isEmpty)
                    const Text('No activity logged yet.')
                  else
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 680),
                          child: DataTable(
                            columnSpacing: 18,
                            horizontalMargin: 16,
                            headingRowHeight: 44,
                            dataRowMinHeight: 44,
                            dataRowMaxHeight: 72,
                            headingRowColor: MaterialStatePropertyAll(
                              scheme.surfaceVariant.withValues(alpha: 130),
                            ),
                            columns: [
                              DataColumn(label: Text('Date', style: headerStyle)),
                              DataColumn(label: Text('Activity', style: headerStyle)),
                              DataColumn(label: Text('User', style: headerStyle)),
                              DataColumn(label: Text('Message', style: headerStyle)),
                            ],
                            rows: sorted.take(8).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final log = entry.value;
                              return DataRow(
                                color: MaterialStatePropertyAll(
                                  index.isEven
                                      ? scheme.surface
                                      : scheme.surfaceVariant.withValues(alpha: 60),
                                ),
                                cells: [
                                  DataCell(Text(_logDate(log.timestamp))),
                                  DataCell(Text(log.type.label)),
                                  DataCell(Text(_actorLabel(log.actorId, userById))),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 320),
                                      child: Text(
                                        log.message.isEmpty ? '--' : log.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
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

  String _actorLabel(String? actorId, Map<String, AppUser> userById) {
    if (actorId == null || actorId.isEmpty) return '--';
    final user = userById[actorId];
    return user?.displayName ?? user?.email ?? actorId;
  }

  String _logDate(DateTime timestamp) {
    return DateFormat('MMM d, HH:mm').format(timestamp);
  }
}
