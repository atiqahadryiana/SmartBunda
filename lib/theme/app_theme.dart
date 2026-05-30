import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Primary palette (Material Design 3 — SmartBunda pink) ──────────────────
  // `darkPink` is the MD3 light Primary and is referenced widely as the brand
  // accent across the app; `primaryPink` is the lighter Secondary tone.
  static const Color darkPink    = Color(0xFFE91E63); // Primary (light)
  static const Color primaryPink = Color(0xFFF48FB1); // Secondary
  static const Color accentPink  = Color(0xFFFF5C8A); // CTA accent

  // MD3 container tokens
  static const Color primaryContainer    = Color(0xFFFCE4EC);
  static const Color onPrimaryContainer  = Color(0xFF880E4F);
  static const Color secondaryContainer  = Color(0xFFF8BBD0);

  // Legacy alias kept for backward compat
  static const Color primaryRose    = darkPink;
  static const Color secondaryPetal = Color(0xFFE59BB4);
  static const Color tertiaryBloom  = Color(0xFFF3C3D2);

  // ── Accent tones (non-pink) ────────────────────────────────────────────────
  static const Color healthcareTeal = Color(0xFF22A6A3);
  static const Color healthcareBlue = Color(0xFF7DB9F0);
  static const Color lavender       = Color(0xFFE7DDFB);

  // ── Surfaces & backgrounds ────────────────────────────────────────────────
  static const Color surfaceBase     = Color(0xFFFFF1F5); // surface variant / soft bg
  static const Color cardBackground  = Color(0xFFFFFFFF); // card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF); // main background
  static const Color background      = Color(0xFFFFFDFD); // app background
  static const Color darkSurface     = Color(0xFF1E1E1E); // dark surface
  static const Color darkBackground  = Color(0xFF121212); // dark background
  static const Color darkElevated    = Color(0xFF2C2227); // dark surface variant

  // ── Semantic colors ───────────────────────────────────────────────────────
  static const Color success     = Color(0xFF66BB6A);
  static const Color warning     = Color(0xFFFFA726);
  static const Color errorColor  = Color(0xFFEF5350);
  static const Color info        = Color(0xFFBA68C8);
  static const Color buttonHover = Color(0xFFFF4081);
  static const Color activeState = Color(0xFFE91E63);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color primaryText  = Color(0xFF1C1B1F);
  static const Color secondaryText = Color(0xFF49454F);
  static const Color disabledText = Color(0xFFBDBDBD);

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// CTA button gradient: pink → accent
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPink, accentPink],
  );

  /// Hero / header section gradient (white → soft pink container)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDFD), Color(0xFFFCE4EC)],
  );

  /// Card soft-blush gradient for tips / banners
  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF1F5), Color(0xFFFCE4EC)],
  );

  // ── Color scheme (light) ──────────────────────────────────────────────────
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: darkPink,
    brightness: Brightness.light,
  ).copyWith(
    primary: darkPink,
    onPrimary: Colors.white,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: primaryPink,
    onSecondary: Colors.white,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onPrimaryContainer,
    tertiary: tertiaryBloom,
    surface: surfaceElevated,
    onSurface: primaryText,
    surfaceContainerHighest: surfaceBase,
    onSurfaceVariant: secondaryText,
    outline: const Color(0xFFD8D8D8),
    outlineVariant: const Color(0xFFF8BBD0),
    error: errorColor,
  );

  // ── Color scheme (dark — neutral near-black with pink accents) ─────────────
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF80AB),
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFFF80AB),
    onPrimary: const Color(0xFF4A001F),
    primaryContainer: const Color(0xFF880E4F),
    onPrimaryContainer: const Color(0xFFFFD9E5),
    secondary: const Color(0xFFF8BBD0),
    onSecondary: const Color(0xFF4A001F),
    secondaryContainer: const Color(0xFF5C2A3A),
    onSecondaryContainer: const Color(0xFFFFD9E5),
    tertiary: const Color(0xFFF3C3D2),
    surface: darkSurface,
    onSurface: Colors.white,
    surfaceContainerHighest: darkElevated,
    onSurfaceVariant: const Color(0xFFCAC4D0),
    outline: const Color(0xFF938F99),
    outlineVariant: const Color(0xFF49454F),
    error: const Color(0xFFEF5350),
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
    final elevated = isDark ? darkSurface : surfaceElevated;

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? darkBackground : background,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: _textTheme(scheme),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : surfaceElevated,
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
