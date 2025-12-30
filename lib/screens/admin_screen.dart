import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../providers/app_providers.dart';
import '../services/auth_repository.dart';
import '../services/service_providers.dart';
import '../widgets/screen_header.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final allEntriesAsync = ref.watch(allEntriesProvider);
    final logsAsync = ref.watch(activityLogsProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('User management')) : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScreenHeader(
            title: 'User management',
            subtitle: 'Create accounts, approve staff, and update access.',
            icon: Icons.admin_panel_settings,
            action: FilledButton.icon(
              onPressed: () => _showCreateUserDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create user'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Pending staff approvals'),
              children: [
                FutureBuilder<List<PendingApproval>>(
                  future: authRepo.pendingApprovals(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading pending approvals...'));
                    }
                    final pending = snapshot.data ?? [];
                    if (pending.isEmpty) {
                      return const ListTile(title: Text('No pending registrations'));
                    }
                    return Column(
                      children: pending
                          .map(
                            (approval) => ListTile(
                              title: Text(approval.email),
                              subtitle: Text(_approvalDetails(approval)),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await authRepo.rejectUser(approval.email);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Rejected ${approval.email}'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Reject'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await authRepo.approveUser(email: approval.email);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Approved ${approval.email} as ${approval.role.label}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.history),
              title: const Text('Recent activity logs'),
              children: [
                logsAsync.when(
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const ListTile(title: Text('No activity logged yet.'));
                    }
                    final sorted = List.of(logs)
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    return Column(
                      children: sorted.take(6).map((log) {
                        return ListTile(
                          title: Text(log.type.label),
                          subtitle: Text(log.message),
                          trailing: Text(
                            '${log.timestamp.month}/${log.timestamp.day}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const ListTile(title: Text('Loading logs...')),
                  error: (e, _) => ListTile(title: Text('Error: $e')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Users', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          usersAsync.when(
            data: (users) {
              final entries = allEntriesAsync.valueOrNull ?? {};
              return Column(
                children: users.map((user) {
                  final list = entries[user.id] ?? <FoodEntry>[];
                  final todayTotals = _todayTotals(list);
                  return Card(
                    child: ListTile(
                      title: Text(user.displayName ?? user.email),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${user.role.label}'),
                          Text('Status: ${user.isActive ? 'Active' : 'Inactive'}'),
                          if (list.isNotEmpty)
                            Text(
                              'Today: ${todayTotals.calories} kcal | P ${todayTotals.protein}g',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditUserDialog(context, ref, user);
                          } else if (value == 'reset') {
                            _showResetPasswordDialog(context, ref, user.email);
                          } else if (value == 'toggle') {
                            ref
                                .read(authRepositoryProvider)
                                .setUserActive(userId: user.id, isActive: !user.isActive);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset password')),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  String _approvalDetails(PendingApproval approval) {
    final details = <String>[
      '${approval.role.label} awaiting approval',
      if (approval.mmcNumber != null && approval.mmcNumber!.isNotEmpty)
        'MMC: ${approval.mmcNumber}',
      if (approval.jlmNumber != null && approval.jlmNumber!.isNotEmpty)
        'JLM: ${approval.jlmNumber}',
    ];
    return details.join(' | ');
  }

  _Totals _todayTotals(List<FoodEntry> entries) {
    final today = DateTime.now();
    var calories = 0, protein = 0;
    for (final e in entries) {
      if (e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day) {
        calories += e.calories;
        protein += e.protein;
      }
    }
    return _Totals(calories, protein);
  }

  Future<void> _showCreateUserDialog(BuildContext context, WidgetRef ref) async {
    await _showUserForm(context, ref, title: 'Create user');
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    await _showUserForm(context, ref, title: 'Edit user', user: user);
  }

  Future<void> _showUserForm(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    AppUser? user,
  }) async {
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final passwordCtrl = TextEditingController();
    var role = user?.role ?? UserRole.patient;
    var isActive = user?.isActive ?? true;
    var permissions =
        Set<AccessPermission>.from(user?.effectivePermissions ?? defaultPermissionsFor(role));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            v != null && v.trim().isNotEmpty ? null : 'Required',
                      ),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: user == null,
                        validator: (v) => v != null && v.contains('@') ? null : 'Valid email',
                      ),
                      if (user == null)
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) =>
                              v != null && v.length >= 6 ? null : 'Min 6 characters',
                        ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<UserRole>(
                        initialValue: role,
                        items: UserRole.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            role = value;
                            permissions = defaultPermissionsFor(role);
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                      SwitchListTile(
                        title: const Text('Active account'),
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Access permissions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...AccessPermission.values.map((permission) {
                        final enabled = permissions.contains(permission);
                        return CheckboxListTile(
                          value: enabled,
                          title: Text(permission.label),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                permissions.add(permission);
                              } else {
                                permissions.remove(permission);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (user == null) {
                await ref.read(authRepositoryProvider).createUser(
                      email: emailCtrl.text.trim(),
                      password: passwordCtrl.text,
                      role: role,
                      displayName: nameCtrl.text.trim(),
                      isActive: isActive,
                      permissions: permissions,
                    );
              } else {
                await ref.read(authRepositoryProvider).updateUser(
                      userId: user.id,
                      displayName: nameCtrl.text.trim(),
                      role: role,
                      isActive: isActive,
                      permissions: permissions,
                    );
              }
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: Text('Send a password reset email to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).adminResetPassword(
                    email: email,
                    newPassword: '',
                  );
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Send email'),
          ),
        ],
      ),
    );
  }
}

class _Totals {
  _Totals(this.calories, this.protein);
  final int calories;
  final int protein;
}
