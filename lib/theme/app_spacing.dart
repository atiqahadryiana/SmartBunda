import 'package:flutter/widgets.dart';

/// SmartBunda spacing, radius, elevation & motion tokens.
///
/// All spacing derives from a 4px base grid. Use these constants instead of
/// hard-coded numbers so layout stays consistent and easy to retune globally.
///
/// ```dart
/// const SizedBox(height: AppSpacing.m);
/// Padding(padding: AppSpacing.screenPadding, child: ...)
/// ```
abstract final class AppSpacing {
  // ── Base 4px grid ────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Common derived insets ─────────────────────────────────────────────────
  /// Default left/right gutter for screen content.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: m, vertical: m);

  /// Horizontal-only gutter (use when vertical spacing is handled per-section).
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: m);

  /// Internal padding for cards & sheets.
  static const EdgeInsets cardPadding = EdgeInsets.all(m);

  /// Gap between stacked cards / list items.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapS = SizedBox(height: s, width: s);
  static const SizedBox gapM = SizedBox(height: m, width: m);
  static const SizedBox gapL = SizedBox(height: l, width: l);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}

/// Corner-radius tokens (MD3 shape scale, tuned to SmartBunda's soft look).
abstract final class AppRadius {
  static const double xs = 8; // chips, small tags
  static const double s = 12; // inputs, small buttons
  static const double m = 16; // buttons, list tiles
  static const double l = 20; // cards
  static const double xl = 28; // sheets, dialogs
  static const double full = 999; // pills, FAB-circular

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius brM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius brL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}

/// Soft, low-spread shadows. SmartBunda uses elevation sparingly — cards are
/// mostly flat with hairline outlines; these are for sheets, FABs & menus.
abstract final class AppElevation {
  /// Resting card / tonal surface (pair with a 1px outline instead of shadow).
  static const double level0 = 0;
  static const double level1 = 1; // app bar scrolled-under, raised button
  static const double level2 = 3; // FAB, menus
  static const double level3 = 6; // dialogs, bottom sheets

  /// A soft, brand-tinted ambient shadow for hero / summary cards.
  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Motion tokens — kept short & calm (no motion-heavy effects, per the
/// accessible/ethical style direction). Always gate non-essential motion on
/// `MediaQuery.disableAnimations` / `prefers-reduced-motion`.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve standard = Curves.easeInOut;
}
