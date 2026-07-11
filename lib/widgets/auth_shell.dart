import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbunda/theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.topAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? topAction;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme;
    final accent = scheme.primary;
    final deep = scheme.onSurface;

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    final titleStyle = GoogleFonts.poppins(
      textStyle:
          (textTheme.headlineSmall ?? const TextStyle(fontSize: 28)).copyWith(
        fontWeight: FontWeight.w700,
        color: deep,
      ),
    );
    final subtitleStyle =
        (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: deep.withValues(alpha: 0.667),
      height: 1.4,
    );

    final theme = base.copyWith(
      textTheme: textTheme.copyWith(
        titleLarge: titleStyle,
        titleMedium: GoogleFonts.poppins(
          textStyle:
              (textTheme.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
            fontWeight: FontWeight.w600,
            color: deep,
          ),
        ),
        titleSmall: GoogleFonts.poppins(
          textStyle:
              (textTheme.titleSmall ?? const TextStyle(fontSize: 16)).copyWith(
            fontWeight: FontWeight.w600,
            color: deep,
          ),
        ),
      ),
      // MD3 filled inputs — fill/borders/labels resolve from the ColorScheme so
      // they stay readable in both light and dark mode.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        labelStyle: (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
            .copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
    );

    final isDark = base.brightness == Brightness.dark;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            // Soft blush background in light mode; flat surface in dark mode.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? null : AppTheme.heroGradient,
                color: isDark ? scheme.surface : null,
              ),
              child: const SizedBox.expand(),
            ),
            // Pink top accent stripe (brand)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                child: SizedBox(height: 5),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topAction != null) topAction!,
                        if (topAction != null) const SizedBox(height: 12),
                        _BrandHeader(
                          title: title,
                          subtitle: subtitle,
                          titleStyle: titleStyle,
                          subtitleStyle: subtitleStyle,
                          accent: accent,
                          deep: deep,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHighest
                                : scheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: scheme.outlineVariant),
                            // Subtle MD3 elevation shadow (no heavy pink glow).
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(
                                    alpha: isDark ? 60 : 22),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 16),
                          Center(child: footer),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accent,
    required this.deep,
  });

  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkPink.withValues(alpha: 0.149),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.favorite, color: AppTheme.darkPink, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
