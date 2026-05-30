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
      color: deep.withValues(alpha: 170),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: deep.withValues(alpha: 40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: deep.withValues(alpha: 40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: deep.withValues(alpha: 140), width: 1.3),
        ),
        labelStyle: (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
            .copyWith(color: deep.withValues(alpha: 150)),
        prefixIconColor: deep.withValues(alpha: 160),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deep,
          side: BorderSide(color: deep.withValues(alpha: 90)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            // Hero blush gradient background
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.heroGradient),
              child: SizedBox.expand(),
            ),
            // Pink top accent stripe
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
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFF8BBD0)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPink
                                    .withValues(alpha: 30),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkPink.withValues(alpha: 70),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 30),
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
