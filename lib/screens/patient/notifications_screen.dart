/// SmartBunda — Patient notifications / alerts screen.
///
/// Surfaces the alerts generated for the signed-in patient (deficiency alerts,
/// reminders, upcoming appointments, calorie warnings, …) from the `Alerts`
/// collection. The patient can mark an alert as read or clear all of them.
library smartbunda.notifications_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/widgets/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          alertsAsync.maybeWhen(
            data: (alerts) => alerts.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: user == null
                        ? null
                        : () => _confirmClear(context, ref, user.id),
                    child: const Text('Clear all'),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alertsProvider),
        child: alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('Could not load notifications: $e')),
          data: (alerts) {
            if (alerts.isEmpty) {
              // Scrollable so pull-to-refresh still works on the empty state.
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'No notifications',
                    message: "You're all caught up. New alerts about your "
                        'nutrition and appointments will appear here.',
                  ),
                ],
              );
            }
            final sorted = List<AlertItem>.from(alerts)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _AlertCard(
                alert: sorted[index],
                onMarkRead: () => ref
                    .read(alertRepositoryProvider)
                    .acknowledge(sorted[index].id),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This removes all of your current notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(alertRepositoryProvider).clearForUser(userId);
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onMarkRead});

  final AlertItem alert;
  final VoidCallback onMarkRead;

  Color get _tone {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppTheme.errorColor;
      case AlertSeverity.medium:
        return AppTheme.warning;
      case AlertSeverity.low:
        return AppTheme.info;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case AlertType.deficiencyAlert:
        return Icons.warning_amber_rounded;
      case AlertType.appointment:
        return Icons.event_outlined;
      case AlertType.reminder:
        return Icons.notifications_active_outlined;
      case AlertType.dietAdvice:
      case AlertType.nutrition:
        return Icons.restaurant_outlined;
      case AlertType.system:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = alert.status.toUpperCase() == 'READ';
    final tone = _tone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead
            ? AppTheme.cardBackground
            : tone.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tone.withValues(alpha: isRead ? 0.094 : 0.314),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: tone, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(alert.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isRead)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
          else
            TextButton(
              onPressed: onMarkRead,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mark read'),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
