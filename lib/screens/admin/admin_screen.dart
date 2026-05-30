import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/auth_repository.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/password_policy.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String _roleFilter = 'all';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _HealthFilter _healthFilter = _HealthFilter.all;
  _DirectorySort _sortOrder = _DirectorySort.az;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final allEntriesAsync = ref.watch(allEntriesProvider);
    final allProfilesAsync = ref.watch(allProfilesProvider);
    final pendingApprovalsAsync = ref.watch(pendingApprovalsProvider);

    return RequireSignIn(
      title: 'User management',
      showAppBar: widget.showAppBar,
      message: 'Please sign in to manage users.',
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: const Text('User management'))
            : null,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: usersAsync.when(
                data: (users) {
                  final entriesByUser = allEntriesAsync.valueOrNull ?? {};
                  final profilesByUser =
                      allProfilesAsync.valueOrNull ?? const <String, Profile>{};
                  final pendingApprovals = pendingApprovalsAsync.valueOrNull ??
                      const <PendingApproval>[];
                  final activeUsers =
                      users.where((user) => user.isActive).length;
                  final inactiveUsers = users.length - activeUsers;
                  final patientUsers = users
                      .where((user) => user.role == UserRole.patient)
                      .length;
                  final staffUsers = users.length - patientUsers;
                  final customAccessPolicies =
                      users.where((user) => user.permissions != null).length;
                  final filteredUsers = _filterUsers(users, profilesByUser);

                  return ListView(
                    children: [
                      _AdminPageHeader(
                        title: 'User Management',
                        subtitle:
                            'Provision new accounts, review staff access, and keep role permissions under control.',
                        onCreateUser: () => _showCreateUserDialog(context, ref),
                      ),
                      const SizedBox(height: 20),
                      _MetricGrid(
                        children: [
                          _AdminMetricTile(
                            title: 'Total users',
                            value: '${users.length}',
                            caption:
                                '$staffUsers staff | $patientUsers patients',
                            icon: Icons.group_outlined,
                            accent: const Color(0xFF0F766E),
                          ),
                          _AdminMetricTile(
                            title: 'Active accounts',
                            value: '$activeUsers',
                            caption: '$inactiveUsers inactive accounts',
                            icon: Icons.verified_user_outlined,
                            accent: const Color(0xFF2563EB),
                          ),
                          _AdminMetricTile(
                            title: 'Pending approvals',
                            value: '${pendingApprovals.length}',
                            caption: pendingApprovals.isEmpty
                                ? 'No staff reviews waiting'
                                : 'Registration requests to review',
                            icon: Icons.pending_actions_outlined,
                            accent: const Color(0xFFB45309),
                          ),
                          _AdminMetricTile(
                            title: 'Custom access',
                            value: '$customAccessPolicies',
                            caption: 'Accounts with manual permissions',
                            icon: Icons.admin_panel_settings_outlined,
                            accent: const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _FilterToolbar(
                        searchController: _searchController,
                        query: _query,
                        roleFilter: _roleFilter,
                        statusFilter: _statusFilter,
                        healthFilter: _healthFilter,
                        sortOrder: _sortOrder,
                        resultCount: filteredUsers.length,
                        totalCount: users.length,
                        onQueryChanged: (value) =>
                            setState(() => _query = value),
                        onRoleChanged: (value) =>
                            setState(() => _roleFilter = value),
                        onStatusChanged: (value) =>
                            setState(() => _statusFilter = value),
                        onHealthChanged: (value) =>
                            setState(() => _healthFilter = value),
                        onSortChanged: (value) =>
                            setState(() => _sortOrder = value),
                        onClear: () {
                          setState(() {
                            _query = '';
                            _roleFilter = 'all';
                            _statusFilter = _StatusFilter.all;
                            _healthFilter = _HealthFilter.all;
                            _sortOrder = _DirectorySort.az;
                          });
                          _searchController.clear();
                        },
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 1040;
                          final left = _PanelCard(
                            title: 'Pending staff approvals',
                            subtitle:
                                'Review clinician and staff registrations before access is granted.',
                            child: pendingApprovalsAsync.when(
                              data: (pending) {
                                if (pending.isEmpty) {
                                  return const _EmptyPanelState(
                                    icon: Icons.verified_user_outlined,
                                    title: 'No approvals waiting',
                                    message:
                                        'New registration requests will appear here when staff sign up.',
                                  );
                                }
                                return Column(
                                  children: pending.map((approval) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _PendingApprovalCard(
                                        approval: approval,
                                        onApprove: () async {
                                          await ref
                                              .read(authRepositoryProvider)
                                              .approveUser(
                                                  email: approval.email);
                                          ref.invalidate(
                                              pendingApprovalsProvider);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Approved ${approval.email} as ${approval.role.label}',
                                              ),
                                            ),
                                          );
                                        },
                                        onReject: () async {
                                          await ref
                                              .read(authRepositoryProvider)
                                              .rejectUser(approval.email);
                                          ref.invalidate(
                                              pendingApprovalsProvider);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Rejected ${approval.email}'),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              error: (error, _) => Text('Error: $error'),
                            ),
                          );

                          final right = _PanelCard(
                            title: 'Access summary',
                            subtitle:
                                'Snapshot of account distribution and access policy',
                            child: Column(
                              children: [
                                _SummaryLine(
                                  label: 'Active accounts',
                                  value: '$activeUsers',
                                ),
                                const Divider(height: 24),
                                _SummaryLine(
                                  label: 'Inactive accounts',
                                  value: '$inactiveUsers',
                                ),
                                const Divider(height: 24),
                                _SummaryLine(
                                  label: 'Default role policies',
                                  value:
                                      '${users.length - customAccessPolicies}',
                                ),
                                const Divider(height: 24),
                                _SummaryLine(
                                  label: 'Custom access policies',
                                  value: '$customAccessPolicies',
                                ),
                                const Divider(height: 24),
                                _SummaryLine(
                                  label: 'Patients',
                                  value: '$patientUsers',
                                ),
                                const Divider(height: 24),
                                _SummaryLine(
                                  label: 'Staff users',
                                  value: '$staffUsers',
                                ),
                              ],
                            ),
                          );

                          if (compact) {
                            return Column(
                              children: [
                                left,
                                const SizedBox(height: 18),
                                right,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: left),
                              const SizedBox(width: 18),
                              Expanded(child: right),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _PanelCard(
                        title: 'User directory',
                        subtitle:
                            'Manage account status, reset credentials, and adjust role-based access.',
                        trailing: Text(
                          'Showing ${filteredUsers.length} of ${users.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        child: _UserDirectory(
                          users: filteredUsers,
                          entriesByUser: entriesByUser,
                          profilesByUser: profilesByUser,
                          onSelected: (action, user) {
                            switch (action) {
                              case _UserAction.edit:
                                _showEditUserDialog(context, ref, user);
                                break;
                              case _UserAction.reset:
                                _showResetPasswordDialog(
                                    context, ref, user.email);
                                break;
                              case _UserAction.toggle:
                                ref.read(authRepositoryProvider).setUserActive(
                                      userId: user.id,
                                      isActive: !user.isActive,
                                    );
                                break;
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<AppUser> _filterUsers(
    List<AppUser> users,
    Map<String, Profile> profilesByUser,
  ) {
    final query = _query.trim().toLowerCase();
    final filtered = users.where((user) {
      final profile = profilesByUser[user.id];
      final matchesQuery = query.isEmpty ||
          (user.displayName ?? '').toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesRole = _roleFilter == 'all' || user.role.name == _roleFilter;
      final matchesStatus = switch (_statusFilter) {
        _StatusFilter.all => true,
        _StatusFilter.active => user.isActive,
        _StatusFilter.inactive => !user.isActive,
      };
      final matchesHealth = switch (_healthFilter) {
        _HealthFilter.all => true,
        _HealthFilter.anyCondition => user.role == UserRole.patient &&
            profile != null &&
            profile.medicalConditions.isNotEmpty,
        _HealthFilter.anemia => user.role == UserRole.patient &&
            profile != null &&
            profile.medicalConditions.contains(MedicalCondition.anemia),
        _HealthFilter.gestationalDiabetes => user.role == UserRole.patient &&
            profile != null &&
            profile.medicalConditions
                .contains(MedicalCondition.gestationalDiabetes),
        _HealthFilter.noneRecorded => user.role == UserRole.patient &&
            (profile == null || profile.medicalConditions.isEmpty),
      };
      return matchesQuery && matchesRole && matchesStatus && matchesHealth;
    }).toList()
      ..sort((a, b) {
        final aLabel = (a.displayName ?? a.email).toLowerCase();
        final bLabel = (b.displayName ?? b.email).toLowerCase();
        final nameCompare = aLabel.compareTo(bLabel);
        if (_sortOrder == _DirectorySort.az) {
          if (nameCompare != 0) return nameCompare;
        } else {
          if (nameCompare != 0) return -nameCompare;
        }
        return a.role.index.compareTo(b.role.index);
      });
    return filtered;
  }

  Future<void> _showCreateUserDialog(
      BuildContext context, WidgetRef ref) async {
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
    var permissions = Set<AccessPermission>.from(
        user?.effectivePermissions ?? defaultPermissionsFor(role));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value != null && value.trim().isNotEmpty
                                ? null
                                : 'Required',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: user == null,
                        validator: (value) =>
                            value != null && value.contains('@')
                                ? null
                                : 'Valid email',
                      ),
                      if (user == null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (value) =>
                              PasswordPolicy.isValid(value ?? '')
                                  ? null
                                  : PasswordPolicy.errorMessage,
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: role,
                        items: UserRole.values
                            .map(
                              (roleValue) => DropdownMenuItem(
                                value: roleValue,
                                child: Text(roleValue.label),
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
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
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
                      const SizedBox(height: 8),
                      ...AccessPermission.values.map((permission) {
                        final enabled = permissions.contains(permission);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
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

enum _StatusFilter { all, active, inactive }

enum _HealthFilter {
  all,
  anyCondition,
  anemia,
  gestationalDiabetes,
  noneRecorded,
}

enum _DirectorySort { az, za }

class _AdminPageHeader extends StatelessWidget {
  const _AdminPageHeader({
    required this.title,
    required this.subtitle,
    required this.onCreateUser,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
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
          final button = FilledButton.icon(
            onPressed: onCreateUser,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Create user'),
          );
          if (constraints.maxWidth < 820) {
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
                button,
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
              button,
            ],
          );
        },
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
            childAspectRatio: columns == 1 ? 3.2 : 1.9,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _AdminMetricTile extends StatelessWidget {
  const _AdminMetricTile({
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

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.searchController,
    required this.query,
    required this.roleFilter,
    required this.statusFilter,
    required this.healthFilter,
    required this.sortOrder,
    required this.resultCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onHealthChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String query;
  final String roleFilter;
  final _StatusFilter statusFilter;
  final _HealthFilter healthFilter;
  final _DirectorySort sortOrder;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<_HealthFilter> onHealthChanged;
  final ValueChanged<_DirectorySort> onSortChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilters = query.isNotEmpty ||
        roleFilter != 'all' ||
        statusFilter != _StatusFilter.all ||
        healthFilter != _HealthFilter.all ||
        sortOrder != _DirectorySort.az;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              _DropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: roleFilter,
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                          value: 'all', child: Text('All roles')),
                      ...UserRole.values.map(
                        (role) => DropdownMenuItem(
                          value: role.name,
                          child: Text(role.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onRoleChanged(value);
                    },
                  ),
                ),
              ),
              _DropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_StatusFilter>(
                    value: statusFilter,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: _StatusFilter.all,
                        child: Text('All statuses'),
                      ),
                      DropdownMenuItem(
                        value: _StatusFilter.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: _StatusFilter.inactive,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onStatusChanged(value);
                    },
                  ),
                ),
              ),
              _DropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_HealthFilter>(
                    value: healthFilter,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: _HealthFilter.all,
                        child: Text('All health profiles'),
                      ),
                      DropdownMenuItem(
                        value: _HealthFilter.anyCondition,
                        child: Text('Any health problem'),
                      ),
                      DropdownMenuItem(
                        value: _HealthFilter.anemia,
                        child: Text('Anemia'),
                      ),
                      DropdownMenuItem(
                        value: _HealthFilter.gestationalDiabetes,
                        child: Text('Gestational diabetes'),
                      ),
                      DropdownMenuItem(
                        value: _HealthFilter.noneRecorded,
                        child: Text('No recorded condition'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onHealthChanged(value);
                    },
                  ),
                ),
              ),
              _DropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_DirectorySort>(
                    value: sortOrder,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: _DirectorySort.az,
                        child: Text('Name A to Z'),
                      ),
                      DropdownMenuItem(
                        value: _DirectorySort.za,
                        child: Text('Name Z to A'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onSortChanged(value);
                    },
                  ),
                ),
              ),
              if (hasFilters)
                OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Showing $resultCount of $totalCount users',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
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

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard({
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  final PendingApproval approval;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = <String>[
      approval.role.label,
      if (approval.displayName != null &&
          approval.displayName!.trim().isNotEmpty)
        approval.displayName!.trim(),
      if (approval.mmcNumber != null && approval.mmcNumber!.trim().isNotEmpty)
        'MMC ${approval.mmcNumber!.trim()}',
      if (approval.jlmNumber != null && approval.jlmNumber!.trim().isNotEmpty)
        'JLM ${approval.jlmNumber!.trim()}',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await onReject();
                },
                child: const Text('Reject'),
              ),
              FilledButton(
                onPressed: () async {
                  await onApprove();
                },
                child: const Text('Approve'),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  details.join(' | '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                actions,
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
                      approval.email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      details.join(' | '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EmptyPanelState extends StatelessWidget {
  const _EmptyPanelState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 60),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _UserDirectory extends StatelessWidget {
  const _UserDirectory({
    required this.users,
    required this.entriesByUser,
    required this.profilesByUser,
    required this.onSelected,
  });

  final List<AppUser> users;
  final Map<String, List<FoodEntry>> entriesByUser;
  final Map<String, Profile> profilesByUser;
  final void Function(_UserAction action, AppUser user) onSelected;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyPanelState(
        icon: Icons.group_off_outlined,
        title: 'No users match the current filters',
        message: 'Try adjusting the search term or filter selections.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 920) {
          return Column(
            children: users.map((user) {
              final totals =
                  _todayTotals(entriesByUser[user.id] ?? const <FoodEntry>[]);
              final profile = profilesByUser[user.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UserCard(
                  user: user,
                  profile: profile,
                  totals: totals,
                  onSelected: (action) => onSelected(action, user),
                ),
              );
            }).toList(),
          );
        }

        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1020),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 70),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      _TableHeaderCell(flex: 3, label: 'User'),
                      _TableHeaderCell(flex: 2, label: 'Role'),
                      _TableHeaderCell(flex: 2, label: 'Status'),
                      _TableHeaderCell(flex: 2, label: 'Today'),
                      _TableHeaderCell(flex: 2, label: 'Access'),
                      _TableHeaderCell(
                        flex: 1,
                        label: 'Actions',
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...users.map((user) {
                  final totals = _todayTotals(
                      entriesByUser[user.id] ?? const <FoodEntry>[]);
                  final profile = profilesByUser[user.id];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UserTableRow(
                      user: user,
                      profile: profile,
                      totals: totals,
                      onSelected: (action) => onSelected(action, user),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  _Totals _todayTotals(List<FoodEntry> entries) {
    final today = DateTime.now();
    var calories = 0;
    var protein = 0;
    for (final entry in entries) {
      if (entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day) {
        calories += entry.calories;
        protein += entry.protein;
      }
    }
    return _Totals(calories, protein);
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({
    required this.flex,
    required this.label,
    this.alignEnd = false,
  });

  final int flex;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
    return Expanded(
      flex: flex,
      child: alignEnd
          ? Align(alignment: Alignment.centerRight, child: text)
          : text,
    );
  }
}

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({
    required this.user,
    required this.profile,
    required this.totals,
    required this.onSelected,
  });

  final AppUser user;
  final Profile? profile;
  final _Totals totals;
  final ValueChanged<_UserAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileSummary = _patientProfileSummary(user, profile);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (profileSummary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profileSummary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(flex: 2, child: _RoleTag(role: user.role)),
          Expanded(flex: 2, child: _StatusTag(isActive: user.isActive)),
          Expanded(
            flex: 2,
            child: Text(
              totals.hasData
                  ? '${totals.calories} kcal | ${totals.protein} g'
                  : 'No intake logged',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.permissions == null
                  ? 'Default role policy'
                  : '${user.effectivePermissions.length} custom permissions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<_UserAction>(
                onSelected: onSelected,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _UserAction.edit,
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.reset,
                    child: Text('Reset password'),
                  ),
                  PopupMenuItem(
                    value: _UserAction.toggle,
                    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.profile,
    required this.totals,
    required this.onSelected,
  });

  final AppUser user;
  final Profile? profile;
  final _Totals totals;
  final ValueChanged<_UserAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileSummary = _patientProfileSummary(user, profile);
    final profileChip = _patientProfileChip(user, profile);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (profileSummary != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profileSummary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_UserAction>(
                onSelected: onSelected,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _UserAction.edit,
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.reset,
                    child: Text('Reset password'),
                  ),
                  PopupMenuItem(
                    value: _UserAction.toggle,
                    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoleTag(role: user.role),
              _StatusTag(isActive: user.isActive),
              _InfoChip(
                label: user.permissions == null
                    ? 'Default role access'
                    : '${user.effectivePermissions.length} custom permissions',
              ),
              if (profileChip != null)
                _InfoChip(
                  label: profileChip,
                  accent: const Color(0xFFB45309),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            totals.hasData
                ? 'Today: ${totals.calories} kcal | Protein ${totals.protein} g'
                : 'Today: No intake logged',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _UserAction { edit, reset, toggle }

String? _patientProfileSummary(AppUser user, Profile? profile) {
  if (user.role != UserRole.patient) return null;
  if (profile == null) return 'Patient profile not completed';

  final parts = <String>[];
  final health = _conditionLabels(profile);
  parts.add(
    health.isEmpty
        ? 'No recorded health problem'
        : 'Health: ${health.join(', ')}',
  );
  final bloodType = profile.bloodType.trim();
  if (bloodType.isNotEmpty) {
    parts.add('Blood $bloodType');
  }
  return parts.join(' | ');
}

String? _patientProfileChip(AppUser user, Profile? profile) {
  if (user.role != UserRole.patient) return null;
  if (profile == null) return 'Profile missing';
  final labels = _conditionLabels(profile);
  return labels.isEmpty ? 'No health problem' : labels.join(', ');
}

List<String> _conditionLabels(Profile profile) {
  final labels = <String>[];
  if (profile.medicalConditions.contains(MedicalCondition.anemia)) {
    labels.add('Anemia');
  }
  if (profile.medicalConditions
      .contains(MedicalCondition.gestationalDiabetes)) {
    labels.add('Gestational diabetes');
  }
  return labels;
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final accent = switch (role) {
      UserRole.admin => const Color(0xFF0F766E),
      UserRole.doctor => const Color(0xFF2563EB),
      UserRole.nurse => const Color(0xFF7C3AED),
      UserRole.patient => const Color(0xFFE85D75),
      UserRole.dietitian => const Color(0xFF65A30D),
    };
    return _InfoChip(label: role.label, accent: accent);
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _InfoChip(
      label: isActive ? 'Active' : 'Inactive',
      accent: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.accent,
  });

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedAccent = accent ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedAccent.withValues(alpha: 12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedAccent.withValues(alpha: 42)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: resolvedAccent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Totals {
  const _Totals(this.calories, this.protein);

  final int calories;
  final int protein;

  bool get hasData => calories > 0 || protein > 0;
}
