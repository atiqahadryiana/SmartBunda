import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SmartBunda design system — Material Design 3.
///
/// Muted, premium maternal-healthcare palette: soft rose pink + white, with a
/// calm healthcare-teal accent. Typography pairs Poppins (headings) with Inter
/// (body) for a warm-but-clinical, accessible read.
///
/// All public colour members below are also surfaced through the active
/// [ColorScheme]; prefer `Theme.of(context).colorScheme.*` in new widgets and
/// reserve the raw constants for gradients / brand splashes. Semantic tones
/// (success / warning / info) adapt to brightness via [SmartBundaColors] —
/// `Theme.of(context).extension<SmartBundaColors>()`.
class AppTheme {
  AppTheme._();

  // ───────────────────────────────────────────────────────────────────────
  // BRAND PALETTE — LIGHT  (spec: muted premium pink)
  // ───────────────────────────────────────────────────────────────────────
  /// MD3 light Primary. Brand rose used for primary actions & the brand accent.
  static const Color darkPink = Color(0xFFD96C8A); // Primary
  /// MD3 light Secondary — a slightly deeper rose for supporting accents.
  static const Color primaryPink = Color(0xFFB85C7A); // Secondary
  /// CTA / gradient end-stop. A touch warmer than Primary for energy in CTAs.
  static const Color accentPink = Color(0xFFE08BA3);

  // Light container tokens (spec)
  static const Color primaryContainer = Color(0xFFFFD9E2);
  static const Color onPrimaryContainer = Color(0xFF4A0017);
  static const Color secondaryContainer = Color(0xFFFFE1E8);
  static const Color onSecondaryContainer = Color(0xFF3A0D1B);

  // Legacy aliases (kept for backward-compat with existing widgets)
  static const Color primaryRose = darkPink;
  static const Color secondaryPetal = primaryPink;
  static const Color tertiaryBloom = Color(0xFFF3C3D2);

  // ── Accent tones (non-pink, for data viz & healthcare cues) ──────────────
  static const Color healthcareTeal = Color(0xFF2A9D9A);
  static const Color healthcareBlue = Color(0xFF0288D1);
  static const Color lavender = Color(0xFFE7DDFB);

  // ───────────────────────────────────────────────────────────────────────
  // SURFACES & BACKGROUNDS
  // ───────────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF8FA); // app background (spec)
  static const Color surfaceElevated = Color(0xFFFFFFFF); // surface (spec)
  static const Color cardBackground = Color(0xFFFFFFFF); // card surface
  static const Color surfaceBase = Color(0xFFF8EFF2); // surface variant (spec)
  static const Color outlineLight = Color(0xFFC9BFC3); // outline (spec)

  static const Color darkBackground = Color(0xFF141218); // (spec)
  static const Color darkSurface = Color(0xFF141218); // (spec)
  static const Color darkElevated = Color(0xFF2C2528); // surface variant (spec)
  static const Color outlineDark = Color(0xFF938F99); // (spec)

  // ───────────────────────────────────────────────────────────────────────
  // SEMANTIC COLOURS  (light defaults; see SmartBundaColors for dark variants)
  // ───────────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32); // (spec)
  static const Color warning = Color(0xFFF57C00); // (spec)
  static const Color info = Color(0xFF0288D1); // (spec)
  static const Color errorColor = Color(0xFFBA1A1A); // (spec)

  // Dark-mode semantic variants (spec)
  static const Color successDark = Color(0xFF81C784);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color infoDark = Color(0xFF4FC3F7);
  static const Color errorDark = Color(0xFFFFB4AB);

  // Interaction helpers
  static const Color buttonHover = Color(0xFFC85C7E);
  static const Color activeState = darkPink;

  // ───────────────────────────────────────────────────────────────────────
  // TEXT  (on light surfaces; on-dark handled by the dark ColorScheme)
  // ───────────────────────────────────────────────────────────────────────
  static const Color primaryText = Color(0xFF1D1B1E); // on background (spec)
  static const Color secondaryText = Color(0xFF534247); // muted, AA on white
  static const Color disabledText = Color(0xFF9E9398);

  // ───────────────────────────────────────────────────────────────────────
  // GRADIENTS
  // ───────────────────────────────────────────────────────────────────────
  /// CTA button gradient: brand rose → warm accent.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPink, accentPink],
  );

  /// Hero / header section gradient (near-white → soft pink container).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, primaryContainer],
  );

  /// Card soft-blush gradient for tips / banners.
  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceBase, primaryContainer],
  );

  // ───────────────────────────────────────────────────────────────────────
  // COLOR SCHEMES  (built explicitly from spec tokens for exact muted tones)
  // ───────────────────────────────────────────────────────────────────────
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: darkPink,
    onPrimary: Colors.white,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: primaryPink,
    onSecondary: Colors.white,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiaryBloom,
    onTertiary: Color(0xFF3A0D1B),
    tertiaryContainer: Color(0xFFFFD9E2),
    onTertiaryContainer: Color(0xFF3A0D1B),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: surfaceElevated,
    onSurface: primaryText,
    onSurfaceVariant: secondaryText,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFFF1F5),
    surfaceContainer: Color(0xFFFCEAEF),
    surfaceContainerHigh: Color(0xFFF8EFF2),
    surfaceContainerHighest: surfaceBase,
    surfaceTint: darkPink,
    outline: outlineLight,
    outlineVariant: Color(0xFFEBDDE2),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF332F31),
    onInverseSurface: Color(0xFFF8EFF2),
    inversePrimary: Color(0xFFFFB1C1),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB1C1), // (spec)
    onPrimary: Color(0xFF5D1128),
    primaryContainer: Color(0xFF7B2942),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFF2B8C6),
    onSecondary: Color(0xFF5A1C30),
    secondaryContainer: Color(0xFF733348),
    onSecondaryContainer: Color(0xFFFFD9E2),
    tertiary: Color(0xFFF3C3D2),
    onTertiary: Color(0xFF3A0D1B),
    tertiaryContainer: Color(0xFF5C2A3A),
    onTertiaryContainer: Color(0xFFFFD9E2),
    error: errorDark,
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: darkSurface,
    onSurface: Color(0xFFE8E0E3), // (spec)
    onSurfaceVariant: Color(0xFFCFC4C8),
    surfaceContainerLowest: Color(0xFF0F0D12),
    surfaceContainerLow: Color(0xFF1C191E),
    surfaceContainer: Color(0xFF211D22),
    surfaceContainerHigh: Color(0xFF2C2528),
    surfaceContainerHighest: darkElevated,
    surfaceTint: Color(0xFFFFB1C1),
    outline: outlineDark,
    outlineVariant: Color(0xFF49454F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE8E0E3),
    onInverseSurface: Color(0xFF332F31),
    inversePrimary: darkPink,
  );

  // ───────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY  — Poppins (display/headline/title) + Inter (body/label)
  // ───────────────────────────────────────────────────────────────────────
  static TextTheme _textTheme(ColorScheme scheme) {
    final heading = GoogleFonts.poppinsTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      // Display & Headline — Poppins
      displayLarge: heading.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium:
          heading.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: heading.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge:
          heading.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          heading.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall:
          heading.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      // Titles — Poppins Medium
      titleLarge: heading.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: heading.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: heading.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      // Body — Inter Regular, generous line-height for readability
      bodyLarge: body.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.5),
      bodySmall: body.bodySmall?.copyWith(height: 1.45),
      // Labels — Inter Medium
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      labelMedium: body.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: body.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  // ───────────────────────────────────────────────────────────────────────
  // THEME BUILDER
  // ───────────────────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);

    final semanticExt = isDark
        ? const SmartBundaColors(
            success: successDark,
            warning: warningDark,
            info: infoDark,
            onSemantic: Color(0xFF141218),
          )
        : const SmartBundaColors(
            success: success,
            warning: warning,
            info: info,
            onSemantic: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: isDark ? darkBackground : background,
      textTheme: textTheme,
      extensions: [semanticExt],
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHigh : cardBackground,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.outline),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size(64, 48), // 48dp ≥ 44px touch target
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          shadowColor: scheme.primary.withValues(alpha: 0.3),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 44),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: GoogleFonts.inter(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        elevation: 2,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            GoogleFonts.inter(color: scheme.onInverseSurface, fontSize: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  static final ThemeData lightTheme = _buildTheme(_lightScheme);
  static final ThemeData darkTheme = _buildTheme(_darkScheme);
}

/// Theme extension carrying brightness-aware semantic colours.
///
/// Usage: `final s = Theme.of(context).extension<SmartBundaColors>()!;`
/// then `s.success`, `s.warning`, `s.info`, and `s.onSemantic` (text/icon
/// colour to lay on top of a filled semantic surface).
@immutable
class SmartBundaColors extends ThemeExtension<SmartBundaColors> {
  const SmartBundaColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.onSemantic,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color onSemantic;

  @override
  SmartBundaColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? onSemantic,
  }) =>
      SmartBundaColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        onSemantic: onSemantic ?? this.onSemantic,
      );

  @override
  SmartBundaColors lerp(ThemeExtension<SmartBundaColors>? other, double t) {
    if (other is! SmartBundaColors) return this;
    return SmartBundaColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onSemantic: Color.lerp(onSemantic, other.onSemantic, t)!,
    );
  }
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
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? AppTheme.primaryGradient
              : LinearGradient(colors: [
                  AppTheme.disabledText.withValues(alpha: 0.4),
                  AppTheme.disabledText.withValues(alpha: 0.4),
                ]),
          borderRadius: BorderRadius.circular(r),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.darkPink.withValues(alpha: 0.28),
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
            splashColor: Colors.white.withValues(alpha: 0.12),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              child: DefaultTextStyle.merge(
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: Center(widthFactor: 1, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
