import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

/// App-wide appearance preference. Mirrors [ThemeMode] but is serialisable to
/// a stable string for SharedPreferences / Firebase persistence.
enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get storageKey => name;

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  static AppThemeMode fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.system;
    }
  }
}

/// Exposes the current [AppThemeMode] and persists changes.
final appThemeModeProvider =
    StateNotifierProvider<ThemeModeController, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeController(prefs);
});

class ThemeModeController extends StateNotifier<AppThemeMode> {
  ThemeModeController(this._prefs) : super(_read(_prefs));

  static const _prefKey = 'app_theme_mode';
  final SharedPreferences _prefs;

  static AppThemeMode _read(SharedPreferences prefs) {
    return AppThemeModeX.fromStorage(prefs.getString(_prefKey));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _prefs.setString(_prefKey, mode.storageKey);
  }
}

/// Whether in-app notifications are enabled. Persisted alongside theme/locale.
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsController, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationsController(prefs);
});

class NotificationsController extends StateNotifier<bool> {
  NotificationsController(this._prefs) : super(_read(_prefs));

  static const _prefKey = 'notifications_enabled';
  final SharedPreferences _prefs;

  static bool _read(SharedPreferences prefs) {
    return prefs.getBool(_prefKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_prefKey, enabled);
  }
}
