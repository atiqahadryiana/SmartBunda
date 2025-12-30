import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final accentAlt = scheme.secondary;
    final deep = scheme.onSurface;
    final surface = scheme.surface;
    final warm = Color.alphaBlend(accentAlt.withValues(alpha: 16), surface);

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    final titleStyle = GoogleFonts.poppins(
      textStyle: (textTheme.headlineSmall ?? const TextStyle(fontSize: 28)).copyWith(
        fontWeight: FontWeight.w700,
        color: deep,
      ),
    );
    final subtitleStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: deep.withValues(alpha: 170),
      height: 1.4,
    );

    final theme = base.copyWith(
      textTheme: textTheme.copyWith(
        titleLarge: titleStyle,
        titleMedium: GoogleFonts.poppins(
          textStyle: (textTheme.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
            fontWeight: FontWeight.w600,
            color: deep,
          ),
        ),
        titleSmall: GoogleFonts.poppins(
          textStyle: (textTheme.titleSmall ?? const TextStyle(fontSize: 16)).copyWith(
            fontWeight: FontWeight.w600,
            color: deep,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deep.withValues(alpha: 40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deep.withValues(alpha: 40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deep.withValues(alpha: 140), width: 1.3),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deep,
          side: BorderSide(color: deep.withValues(alpha: 90)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    surface,
                    Color.alphaBlend(accentAlt.withValues(alpha: 20), surface),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -60,
              child: _GlowCircle(color: accentAlt.withValues(alpha: 60), size: 220),
            ),
            Positioned(
              bottom: -100,
              left: -40,
              child: _GlowCircle(color: accent.withValues(alpha: 35), size: 260),
            ),
            Positioned(
              top: 140,
              left: -20,
              child: _GlowCircle(
                color: Colors.white.withValues(alpha: 200),
                size: 120,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surface.withValues(alpha: 245),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 220)),
                            boxShadow: [
                              BoxShadow(
                                color: accentAlt.withValues(alpha: 18),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 210)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 60),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 28),
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
