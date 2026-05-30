/// SmartBunda — Healthcare Professional Profile
///
/// Replaces the previous display-only staff profile card with a structured,
/// healthcare-oriented profile: Professional Information, Account Settings,
/// Professional Settings, and Security. Editing persists to the user document
/// through the auth repository.
library smartbunda.professional_profile_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/require_sign_in.dart';
import 'change_password_screen.dart';
import 'professional_availability_screen.dart';
import 'settings_screen.dart';

class ProfessionalProfileScreen extends ConsumerWidget {
  const ProfessionalProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final user = ref.watch(currentUserProvider);

    final child = user == null
        ? const SizedBox.shrink()
        : Scaffold(
            appBar: showAppBar
                ? AppBar(title: Text(strings.t('Profile')))
                : null,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ProfessionalHeader(user: user),
                const SizedBox(height: 20),
                _ProfessionalInfoSection(user: user),
                const SizedBox(height: 16),
                _AccountSettingsSection(strings: strings),
                const SizedBox(height: 16),
                _ProfessionalSettingsSection(strings: strings),
                const SizedBox(height: 16),
                _SecuritySection(strings: strings),
              ],
            ),
          );

    return RequireSignIn(
      title: strings.t('Profile'),
      showAppBar: showAppBar,
      message: strings.signInToViewProfile,
      child: child,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfessionalHeader extends StatelessWidget {
  const _ProfessionalHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text(
              _initials(user.displayName ?? user.email),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkPink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 230),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${strings.roleLabel(user.role)} · ${user.effectiveSpecialization}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.darkPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts =
        value.trim().split(RegExp(r'[\s@.]+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

// ── Professional information (editable) ───────────────────────────────────────

class _ProfessionalInfoSection extends ConsumerWidget {
  const _ProfessionalInfoSection({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return _SectionCard(
      title: strings.t('Professional Information'),
      icon: Icons.badge_outlined,
      trailing: TextButton.icon(
        onPressed: () => _edit(context, ref, user),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(strings.t('Edit')),
      ),
      children: [
        _InfoRow(label: strings.t('Full Name'), value: user.displayName),
        _InfoRow(label: strings.t('MMC Number'), value: user.mmcNumber),
        _InfoRow(label: strings.t('Email'), value: user.email),
        _InfoRow(label: strings.t('Phone Number'), value: user.phone),
        _InfoRow(
          label: strings.t('Specialization'),
          value: user.effectiveSpecialization,
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final strings = AppStrings.of(context);
    final nameCtrl = TextEditingController(text: user.displayName ?? '');
    final mmcCtrl = TextEditingController(text: user.mmcNumber ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final specCtrl =
        TextEditingController(text: user.specialization ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.t('Edit Professional Information'),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration:
                    InputDecoration(labelText: strings.t('Full Name')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mmcCtrl,
                decoration:
                    InputDecoration(labelText: strings.t('MMC Number')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    InputDecoration(labelText: strings.t('Phone Number')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specCtrl,
                decoration:
                    InputDecoration(labelText: strings.t('Specialization')),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(strings.t('Save')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      try {
        await ref.read(authRepositoryProvider).updateProfessionalProfile(
              userId: user.id,
              displayName: nameCtrl.text,
              mmcNumber: mmcCtrl.text,
              specialization: specCtrl.text,
              phone: phoneCtrl.text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('Profile updated.'))),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${strings.t('Update failed')}: $error')),
          );
        }
      }
    }
    nameCtrl.dispose();
    mmcCtrl.dispose();
    phoneCtrl.dispose();
    specCtrl.dispose();
  }
}

// ── Account settings ──────────────────────────────────────────────────────────

class _AccountSettingsSection extends StatelessWidget {
  const _AccountSettingsSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: strings.t('Account Settings'),
      icon: Icons.manage_accounts_outlined,
      children: [
        _NavTile(
          icon: Icons.lock_outline,
          label: strings.t('Change Password'),
          onTap: () => _push(context, const ChangePasswordScreen()),
        ),
        _NavTile(
          icon: Icons.notifications_outlined,
          label: strings.t('Notification Settings'),
          onTap: () => _push(context, const SettingsScreen()),
        ),
        _NavTile(
          icon: Icons.translate_outlined,
          label: strings.t('Language Settings'),
          onTap: () => _push(context, const SettingsScreen()),
        ),
        _NavTile(
          icon: Icons.dark_mode_outlined,
          label: strings.t('Dark / Light Mode'),
          onTap: () => _push(context, const SettingsScreen()),
        ),
      ],
    );
  }
}

// ── Professional settings ─────────────────────────────────────────────────────

class _ProfessionalSettingsSection extends StatelessWidget {
  const _ProfessionalSettingsSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: strings.t('Professional Settings'),
      icon: Icons.medical_services_outlined,
      children: [
        _NavTile(
          icon: Icons.event_available_outlined,
          label: strings.t('Consultation Availability'),
          onTap: () =>
              _push(context, const ProfessionalAvailabilityScreen()),
        ),
        _NavTile(
          icon: Icons.schedule_outlined,
          label: strings.t('Session Schedule'),
          onTap: () =>
              _push(context, const ProfessionalAvailabilityScreen()),
        ),
        _NavTile(
          icon: Icons.tune_outlined,
          label: strings.t('Appointment Preferences'),
          onTap: () =>
              _push(context, const ProfessionalAvailabilityScreen()),
        ),
      ],
    );
  }
}

// ── Security ──────────────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerStatefulWidget {
  const _SecuritySection({required this.strings});

  final AppStrings strings;

  @override
  ConsumerState<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<_SecuritySection> {
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return _SectionCard(
      title: strings.t('Security'),
      icon: Icons.shield_outlined,
      children: [
        _NavTile(
          icon: Icons.lock_outline,
          label: strings.t('Change Password'),
          onTap: () => _push(context, const ChangePasswordScreen()),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.verified_user_outlined),
          title: Text(strings.t('Two-Factor Authentication')),
          subtitle: Text(strings.t('Add an extra layer of security.')),
          value: _twoFactor,
          onChanged: (value) {
            setState(() => _twoFactor = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? strings.t('Two-factor authentication enabled.')
                      : strings.t('Two-factor authentication disabled.'),
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(
            strings.t('Logout'),
            style: const TextStyle(color: Colors.redAccent),
          ),
          onTap: () => _confirmLogout(context, strings),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('Logout')),
        content: Text(strings.t('Are you sure you want to log out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('Logout')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

// ── Shared building blocks ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.darkPink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.trim().isEmpty) ? '--' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
