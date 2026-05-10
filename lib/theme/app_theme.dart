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
  static const Color primaryRose = Color(0xFFC24879);
  static const Color secondaryPetal = Color(0xFFE59BB4);
  static const Color tertiaryBloom = Color(0xFFF3C3D2);
  static const Color surfaceBase = Color(0xFFFFF7FA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: primaryRose,
    brightness: Brightness.light,
  ).copyWith(
    primary: primaryRose,
    onPrimary: Colors.white,
    secondary: secondaryPetal,
    tertiary: tertiaryBloom,
    surface: surfaceBase,
    onSurface: const Color(0xFF2F1F27),
    onSurfaceVariant: const Color(0xFF6F5561),
    surfaceContainerHighest: const Color(0xFFF5E2E9),
    outlineVariant: const Color(0xFFE8D2DA),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightScheme.primary, width: 1.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: _lightScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: _lightScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightScheme.primary,
        side: BorderSide(color: _lightScheme.primary.withValues(alpha: 140)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
