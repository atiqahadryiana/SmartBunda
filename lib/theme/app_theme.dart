import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Primary palette ───────────────────────────────────────────────────────
  static const Color primaryPink = Color(0xFFF48FB1);
  static const Color darkPink    = Color(0xFFEC407A);
  static const Color accentPink  = Color(0xFFFF5C8A);

  // Legacy alias kept for backward compat
  static const Color primaryRose    = darkPink;
  static const Color secondaryPetal = Color(0xFFE59BB4);
  static const Color tertiaryBloom  = Color(0xFFF3C3D2);

  // ── Accent tones (non-pink) ────────────────────────────────────────────────
  static const Color healthcareTeal = Color(0xFF22A6A3);
  static const Color healthcareBlue = Color(0xFF7DB9F0);
  static const Color lavender       = Color(0xFFE7DDFB);

  // ── Surfaces & backgrounds ────────────────────────────────────────────────
  static const Color surfaceBase     = Color(0xFFFFF5F8); // secondary bg
  static const Color cardBackground  = Color(0xFFFDF9FA); // card bg
  static const Color surfaceElevated = Color(0xFFFFFFFF); // main bg
  static const Color darkSurface     = Color(0xFF111A22);
  static const Color darkElevated    = Color(0xFF18242E);

  // ── Semantic colors ───────────────────────────────────────────────────────
  static const Color success     = Color(0xFF66BB6A);
  static const Color warning     = Color(0xFFFFA726);
  static const Color errorColor  = Color(0xFFEF5350);
  static const Color info        = Color(0xFFBA68C8);
  static const Color buttonHover = Color(0xFFFF4081);
  static const Color activeState = Color(0xFFE91E63);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color primaryText  = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF757575);
  static const Color disabledText = Color(0xFFBDBDBD);

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// CTA button gradient: pink → accent
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, accentPink],
  );

  /// Hero / header section gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF5F8), Color(0xFFFCE4EC)],
  );

  /// Card soft-blush gradient for tips / banners
  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF5F8), Color(0xFFFCE4EC)],
  );

  // ── Color scheme ──────────────────────────────────────────────────────────
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: primaryPink,
    brightness: Brightness.light,
  ).copyWith(
    primary: darkPink,
    onPrimary: Colors.white,
    secondary: primaryPink,
    tertiary: tertiaryBloom,
    surface: surfaceBase,
    onSurface: primaryText,
    onSurfaceVariant: secondaryText,
    surfaceContainerHighest: const Color(0xFFF5E2E9),
    outlineVariant: const Color(0xFFF8BBD0),
    error: errorColor,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: healthcareTeal,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFFF8DB5),
    onPrimary: const Color(0xFF2A111B),
    secondary: const Color(0xFF66D7D2),
    tertiary: const Color(0xFFBCAAF4),
    surface: darkSurface,
    onSurface: const Color(0xFFF6F0F4),
    onSurfaceVariant: const Color(0xFFC4CDD5),
    surfaceContainerHighest: darkElevated,
    outlineVariant: const Color(0xFF344650),
    error: errorColor,
  );

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.poppinsTextTheme();
    return base
        .copyWith(
          headlineLarge:
              base.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          headlineMedium:
              base.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          headlineSmall:
              base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge:  base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall:  base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge:  base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge:   base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium:  base.bodyMedium?.copyWith(height: 1.45),
          bodySmall:   base.bodySmall?.copyWith(height: 1.4),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  // ── Theme builder ─────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final elevated = isDark ? darkElevated : surfaceElevated;

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? darkSurface : surfaceBase,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: _textTheme(scheme),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkElevated : surfaceElevated,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? darkElevated : cardBackground,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark
                ? scheme.outlineVariant
                : const Color(0xFFF8BBD0),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPink,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPink,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          shadowColor: darkPink.withValues(alpha: 80),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPink,
          side: BorderSide(color: darkPink.withValues(alpha: 130)),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPink,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            scheme.surfaceContainerHighest.withValues(alpha: 130),
        selectedColor: primaryPink.withValues(alpha: 50),
        labelStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: darkPink,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: primaryPink.withValues(alpha: 30),
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: elevated.withValues(alpha: 235),
        indicatorColor: primaryPink.withValues(alpha: 35),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            color: scheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: darkPink.withValues(alpha: 210)),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPink,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static ThemeData lightTheme = _buildTheme(_lightScheme, Brightness.light);
  static ThemeData darkTheme  = _buildTheme(_darkScheme, Brightness.dark);
}

/// Gradient button — wraps any child in the CTA gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? AppTheme.primaryGradient
            : const LinearGradient(
                colors: [Color(0xFFBDBDBD), Color(0xFFBDBDBD)]),
        borderRadius: BorderRadius.circular(r),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.darkPink.withValues(alpha: 70),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(r),
          splashColor: Colors.white.withValues(alpha: 30),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
