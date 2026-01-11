import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    final usersAsync = ref.watch(usersProvider);

    return RequireSignIn(
      title: 'Activity logs',
      showAppBar: showAppBar,
      message: 'Please sign in to view activity logs.',
      child: Scaffold(
        appBar: showAppBar ? AppBar(title: const Text('Activity logs')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: logsAsync.when(
            data: (logs) {
              final users = usersAsync.valueOrNull ?? const <AppUser>[];
              final userMap = {for (final user in users) user.id: user};
              final sorted = List<ActivityLogEntry>.from(logs)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              if (sorted.isEmpty) {
                return const EmptyState(
                  icon: Icons.history,
                  title: 'No activity yet',
                  message: 'Activity will appear here as users sign in and update data.',
                );
              }
              return ListView(
                children: [
                  const ScreenHeader(
                    title: 'Activity logs',
                    subtitle: 'Review recent logins, updates, and approvals.',
                    icon: Icons.history,
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = sorted[index];
                      final actor = userMap[log.actorId];
                      final subject = userMap[log.subjectId];
                      final who = actor?.displayName ?? actor?.email ?? 'System';
                      final target = subject == null
                          ? ''
                          : ' | Target: ${subject.displayName ?? subject.email}';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(log.type.label),
                          subtitle: Text('$who$target\n${log.message}'),
                          trailing: Text(
                            '${log.timestamp.month}/${log.timestamp.day} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
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
      ),
    );
  }
}
