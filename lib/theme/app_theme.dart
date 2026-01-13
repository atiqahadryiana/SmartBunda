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
  static const Color primaryPink = Color(0xFFFF4D8D);
  static const Color secondaryPink = Color(0xFFFFA1C2);
  static const Color tertiaryPeach = Color(0xFFFFC7A8);
  static const Color surfaceBase = Color(0xFFFFF4F8);
  static const Color surfaceElevated = Color(0xFFFFFBFD);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: primaryPink,
    brightness: Brightness.light,
  ).copyWith(
    primary: primaryPink,
    secondary: secondaryPink,
    tertiary: tertiaryPeach,
    surface: surfaceBase,
    surfaceContainerHighest: const Color(0xFFFFE4EE),
    outlineVariant: const Color(0xFFF5C5D7),
  );

  static ThemeData lightTheme = ThemeData(
    colorScheme: _lightScheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surfaceBase,
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
      color: surfaceElevated,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
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
