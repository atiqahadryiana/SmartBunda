import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/activity_log.dart';
import '../models/alert_item.dart';
import '../models/app_user.dart';
import '../models/appointment.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final logsAsync = ref.watch(activityLogsProvider);
    final alerts =
        ref.watch(allAlertsProvider).valueOrNull ?? const <AlertItem>[];
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final pendingApprovals =
        ref.watch(pendingApprovalsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Overview')) : null,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: usersAsync.when(
              data: (users) => logsAsync.when(
                data: (logs) => _OverviewContent(
                  users: users,
                  logs: logs,
                  alerts: alerts,
                  appointments: appointments,
                  pendingApprovals: pendingApprovals.length,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.users,
    required this.logs,
    required this.alerts,
    required this.appointments,
    required this.pendingApprovals,
  });

  final List<AppUser> users;
  final List<ActivityLogEntry> logs;
  final List<AlertItem> alerts;
  final List<Appointment> appointments;
  final int pendingApprovals;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sortedLogs = List.of(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final activeUsers = users.where((user) => user.isActive).length;
    final inactiveUsers = users.length - activeUsers;
    final patientUsers =
        users.where((user) => user.role == UserRole.patient).length;
    final staffUsers = users.length - patientUsers;
    final loginsLast7Days = sortedLogs
        .where(
          (log) =>
              log.type == ActivityType.login &&
              now.difference(log.timestamp).inDays < 7,
        )
        .length;
    final highPriorityAlerts = alerts
        .where(
          (alert) =>
              alert.severity == AlertSeverity.high &&
              now.difference(alert.createdAt).inDays < 7,
        )
        .length;
    final upcomingAppointments = appointments
        .where(
          (appointment) =>
              appointment.dateTime.isAfter(now) &&
              appointment.dateTime.isBefore(now.add(const Duration(days: 7))) &&
              appointment.status.toUpperCase() == 'SCHEDULED',
        )
        .length;
    final recentRegistrations = sortedLogs
        .where(
          (log) =>
              (log.type == ActivityType.register ||
                  log.type == ActivityType.userCreated) &&
              now.difference(log.timestamp).inDays < 30,
        )
        .length;
    final roleCounts = {
      for (final role in UserRole.values)
        role: users.where((user) => user.role == role).length,
    };
    final userById = {for (final user in users) user.id: user};

    return ListView(
      children: [
        _PageHeader(
          title: 'Admin Dashboard',
          subtitle:
              'Track platform activity, account health, and short-term operational workload.',
          primaryMeta:
              'Updated ${DateFormat('d MMM yyyy, h:mm a').format(now)}',
          secondaryMeta: '$pendingApprovals pending approvals',
        ),
        const SizedBox(height: 20),
        _MetricGrid(
          children: [
            _MetricTile(
              title: 'Total accounts',
              value: '${users.length}',
              caption: '$staffUsers staff | $patientUsers patients',
              icon: Icons.groups_2_outlined,
              accent: const Color(0xFF0F766E),
            ),
            _MetricTile(
              title: 'Active accounts',
              value: '$activeUsers',
              caption: '$inactiveUsers inactive accounts',
              icon: Icons.verified_user_outlined,
              accent: const Color(0xFF2563EB),
            ),
            _MetricTile(
              title: 'Pending approvals',
              value: '$pendingApprovals',
              caption: pendingApprovals == 0
                  ? 'No reviews waiting'
                  : 'Staff registrations awaiting review',
              icon: Icons.pending_actions_outlined,
              accent: const Color(0xFFB45309),
            ),
            _MetricTile(
              title: 'Login activity',
              value: '$loginsLast7Days',
              caption: 'Sign-ins recorded in the last 7 days',
              icon: Icons.login_outlined,
              accent: const Color(0xFF475569),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 1040;
            final primaryColumn = Column(
              children: [
                _DashboardPanel(
                  title: 'Recent activity',
                  subtitle: 'Latest audit events across the platform',
                  child: _ActivityTable(
                    logs: sortedLogs.take(8).toList(),
                    userById: userById,
                  ),
                ),
                const SizedBox(height: 18),
                _DashboardPanel(
                  title: 'Operational summary',
                  subtitle: 'Short-term workload and system signals',
                  child: Column(
                    children: [
                      _SummaryRow(
                        icon: Icons.warning_amber_rounded,
                        title: 'High-priority alerts',
                        subtitle: 'Raised in the last 7 days',
                        value: '$highPriorityAlerts',
                        accent: const Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.event_available_outlined,
                        title: 'Upcoming appointments',
                        subtitle: 'Scheduled for the next 7 days',
                        value: '$upcomingAppointments',
                        accent: const Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'New accounts',
                        subtitle: 'Registered or created in the last 30 days',
                        value: '$recentRegistrations',
                        accent: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final secondaryColumn = Column(
              children: [
                _DashboardPanel(
                  title: 'User distribution',
                  subtitle: 'Current account mix by role',
                  child: Column(
                    children: UserRole.values.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RoleDistributionRow(
                          role: role,
                          count: roleCounts[role] ?? 0,
                          total: users.length,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                _DashboardPanel(
                  title: 'Review queue',
                  subtitle: 'Approval and access management focus',
                  child: Column(
                    children: [
                      _QueueStat(
                        label: 'Pending staff approvals',
                        value: '$pendingApprovals',
                      ),
                      const Divider(height: 24),
                      _QueueStat(
                        label: 'Inactive accounts',
                        value: '$inactiveUsers',
                      ),
                      const Divider(height: 24),
                      _QueueStat(
                        label: 'Patients',
                        value: '$patientUsers',
                      ),
                      const Divider(height: 24),
                      _QueueStat(
                        label: 'Staff users',
                        value: '$staffUsers',
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                children: [
                  primaryColumn,
                  const SizedBox(height: 18),
                  secondaryColumn,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: primaryColumn),
                const SizedBox(width: 18),
                Expanded(child: secondaryColumn),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.primaryMeta,
    required this.secondaryMeta,
  });

  final String title;
  final String subtitle;
  final String primaryMeta;
  final String secondaryMeta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final meta = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderMetaChip(
                  icon: Icons.schedule_outlined, label: primaryMeta),
              _HeaderMetaChip(
                icon: Icons.pending_actions_outlined,
                label: secondaryMeta,
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                meta,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(width: 340, child: meta),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  const _HeaderMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 820
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 3.2 : 1.85,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 5),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({
    required this.logs,
    required this.userById,
  });

  final List<ActivityLogEntry> logs;
  final Map<String, AppUser> userById;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Text('No activity logged yet.');
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 70),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Activity',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'User',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Message',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Time',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...logs.map((log) {
          final actor = _actorLabel(log.actorId, userById);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityTableRow(log: log, actorLabel: actor),
          );
        }),
      ],
    );
  }

  String _actorLabel(String? actorId, Map<String, AppUser> userById) {
    if (actorId == null || actorId.isEmpty) return 'System';
    final user = userById[actorId];
    return user?.displayName ?? user?.email ?? actorId;
  }
}

class _ActivityTableRow extends StatelessWidget {
  const _ActivityTableRow({
    required this.log,
    required this.actorLabel,
  });

  final ActivityLogEntry log;
  final String actorLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _activityAccent(log.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_activityIcon(log.type), color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      log.type.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                actorLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                log.message.isEmpty ? 'No message provided.' : log.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _timeAgo(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _activityAccent(ActivityType type) {
    switch (type) {
      case ActivityType.login:
      case ActivityType.logout:
        return const Color(0xFF0F766E);
      case ActivityType.register:
      case ActivityType.approvalRequested:
      case ActivityType.approvalCompleted:
        return const Color(0xFFB45309);
      case ActivityType.userCreated:
      case ActivityType.userUpdated:
      case ActivityType.userDeactivated:
        return const Color(0xFF2563EB);
      case ActivityType.passwordResetRequested:
      case ActivityType.passwordResetCompleted:
      case ActivityType.passwordResetAdmin:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.login:
        return Icons.login_outlined;
      case ActivityType.logout:
        return Icons.logout_outlined;
      case ActivityType.register:
      case ActivityType.approvalRequested:
        return Icons.person_add_alt_1_outlined;
      case ActivityType.approvalCompleted:
        return Icons.task_alt_outlined;
      case ActivityType.userCreated:
        return Icons.person_add_outlined;
      case ActivityType.userUpdated:
        return Icons.edit_outlined;
      case ActivityType.userDeactivated:
        return Icons.person_off_outlined;
      case ActivityType.passwordResetRequested:
      case ActivityType.passwordResetCompleted:
      case ActivityType.passwordResetAdmin:
        return Icons.lock_reset_outlined;
    }
  }

  String _timeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('d MMM').format(timestamp);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RoleDistributionRow extends StatelessWidget {
  const _RoleDistributionRow({
    required this.role,
    required this.count,
    required this.total,
  });

  final UserRole role;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _roleAccent(role);
    final share = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_roleIcon(role), size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                role.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: share.clamp(0.0, 1.0),
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(share * 100).toStringAsFixed(0)}% of all accounts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Color _roleAccent(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF0F766E);
      case UserRole.doctor:
        return const Color(0xFF2563EB);
      case UserRole.nurse:
        return const Color(0xFF7C3AED);
      case UserRole.patient:
        return const Color(0xFFE85D75);
      case UserRole.dietitian:
        return const Color(0xFF65A30D);
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.doctor:
        return Icons.medical_services_outlined;
      case UserRole.nurse:
        return Icons.health_and_safety_outlined;
      case UserRole.patient:
        return Icons.person_outline;
      case UserRole.dietitian:
        return Icons.restaurant_menu_outlined;
    }
  }
}

class _QueueStat extends StatelessWidget {
  const _QueueStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
