import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class AppTheme {
  static const Color primaryMint = Color(0xFF2EC4B6);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentSun = Color(0xFFFFD166);
  static const Color surfaceBase = Color(0xFFFFF7F2);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: primaryMint,
    brightness: Brightness.light,
  ).copyWith(
    primary: primaryMint,
    secondary: accentCoral,
    tertiary: accentSun,
    surface: const Color(0xFFFFFEF9),
  );

  static ThemeData lightTheme = ThemeData(
    colorScheme: _lightScheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightScheme.surface,
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: _lightScheme.onSurface,
      displayColor: _lightScheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.surface,
      foregroundColor: _lightScheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _lightScheme.surface,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightScheme.primary, width: 1.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: _lightScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: _lightScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightScheme.primary,
        side: BorderSide(color: _lightScheme.primary.withValues(alpha: 140)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightScheme.primary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _lightScheme.secondary.withValues(alpha: 38),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: _lightScheme.onSurface, fontSize: 12),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: _lightScheme.primary.withValues(alpha: 200)),
      ),
    ),
  );

  static ThemeData darkTheme = lightTheme;
}
