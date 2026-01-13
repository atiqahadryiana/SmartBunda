import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not initialized.');
});

final appLocaleProvider = StateNotifierProvider<AppLocaleController, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLocaleController(prefs);
});

class AppLocaleController extends StateNotifier<Locale> {
  AppLocaleController(this._prefs) : super(_readLocale(_prefs));

  static const _prefKey = 'app_locale';
  final SharedPreferences _prefs;

  static Locale _readLocale(SharedPreferences prefs) {
    final code = prefs.getString(_prefKey);
    if (code == 'ms') return const Locale('ms');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_prefKey, locale.languageCode);
  }
}
