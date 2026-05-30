/// SmartBunda — Settings Screen
///
/// Accessible from the profile screens (patient + healthcare professional).
/// Lets the user change language, appearance (light/dark/system), notification
/// preferences, and open the legal / about pages. Choices are persisted to
/// SharedPreferences immediately and mirrored to Firebase via the auth repo.
library smartbunda.settings_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/service_providers.dart';
import '../theme/app_theme.dart';
import 'legal/info_page_screen.dart';

/// App version label shown on the About page. Keep in sync with pubspec.yaml.
const String kAppVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Language ──────────────────────────────────────────────────────
          _SettingsSection(
            title: strings.t('Language'),
            icon: Icons.translate_outlined,
            children: [
              RadioGroup<String>(
                groupValue: locale.languageCode,
                onChanged: (value) => _setLocale(ref, value),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      value: 'en',
                      title: Text('English'),
                    ),
                    RadioListTile<String>(
                      value: 'ms',
                      title: Text('Bahasa Melayu'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Appearance ────────────────────────────────────────────────────
          _SettingsSection(
            title: strings.t('Appearance'),
            icon: Icons.palette_outlined,
            children: [
              RadioGroup<AppThemeMode>(
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) _setTheme(ref, value);
                },
                child: Column(
                  children: [
                    for (final mode in AppThemeMode.values)
                      RadioListTile<AppThemeMode>(
                        value: mode,
                        title: Text(strings.t(mode.label)),
                        secondary: Icon(_themeIcon(mode)),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Notifications ─────────────────────────────────────────────────
          _SettingsSection(
            title: strings.t('Notifications'),
            icon: Icons.notifications_outlined,
            children: [
              SwitchListTile(
                value: notificationsEnabled,
                onChanged: (value) => _setNotifications(ref, value),
                title: Text(strings.t('Allow notifications')),
                subtitle: Text(
                  strings.t('Receive reminders and health alerts.'),
                ),
              ),
            ],
          ),

          // ── Additional ────────────────────────────────────────────────────
          _SettingsSection(
            title: strings.t('Additional Settings'),
            icon: Icons.tune_outlined,
            children: [
              _LinkTile(
                icon: Icons.privacy_tip_outlined,
                label: strings.t('Privacy Policy'),
                onTap: () => _open(
                  context,
                  SmartBundaInfoPages.privacyPolicy(strings),
                ),
              ),
              _LinkTile(
                icon: Icons.description_outlined,
                label: strings.t('Terms & Conditions'),
                onTap: () => _open(
                  context,
                  SmartBundaInfoPages.termsAndConditions(strings),
                ),
              ),
              _LinkTile(
                icon: Icons.support_agent_outlined,
                label: strings.t('Help & Support'),
                onTap: () => _open(
                  context,
                  SmartBundaInfoPages.helpAndSupport(strings),
                ),
              ),
              _LinkTile(
                icon: Icons.info_outline,
                label: strings.t('About SmartBunda'),
                onTap: () => _open(
                  context,
                  SmartBundaInfoPages.about(strings, version: kAppVersion),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  void _setLocale(WidgetRef ref, String? code) {
    if (code == null) return;
    ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
    _persist(ref, {'locale': code});
  }

  void _setTheme(WidgetRef ref, AppThemeMode mode) {
    ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
    _persist(ref, {'themeMode': mode.storageKey});
  }

  void _setNotifications(WidgetRef ref, bool enabled) {
    ref.read(notificationsEnabledProvider.notifier).setEnabled(enabled);
    _persist(ref, {'notificationsEnabled': enabled});
  }

  /// Mirror the chosen setting to Firebase under the user document. Best-effort;
  /// local SharedPreferences remains the source of truth for startup.
  void _persist(WidgetRef ref, Map<String, dynamic> settings) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    ref
        .read(authRepositoryProvider)
        .saveUserSettings(userId: user.id, settings: settings)
        .catchError((_) {/* ignore network errors; local copy persists */});
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.darkPink),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkPink,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
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
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
