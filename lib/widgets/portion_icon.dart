/// SmartBunda — portion pie icon.
///
/// Draws a small pie/plate glyph that fills a fraction of a circle to convey
/// the serving size at a glance (1/3, 1/2, 2/3, 3/4, or a full plate). Used as
/// the leading widget on food list rows so users can scan portions visually.
library smartbunda.portion_icon;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smartbunda/theme/app_theme.dart';

/// The discrete plate portions SmartBunda recognises, in ascending size.
enum PlatePortion { third, half, twoThirds, threeQuarters, full }

extension PlatePortionX on PlatePortion {
  /// Filled fraction of the plate (0–1).
  double get fraction => switch (this) {
        PlatePortion.third => 1 / 3,
        PlatePortion.half => 1 / 2,
        PlatePortion.twoThirds => 2 / 3,
        PlatePortion.threeQuarters => 3 / 4,
        PlatePortion.full => 1.0,
      };

  /// Short human-readable label, e.g. "1/2 plate".
  String get label => switch (this) {
        PlatePortion.third => '1/3 plate',
        PlatePortion.half => '1/2 plate',
        PlatePortion.twoThirds => '2/3 plate',
        PlatePortion.threeQuarters => '3/4 plate',
        PlatePortion.full => '1 plate',
      };
}

/// Infers the plate portion from a free-text serving string such as
/// "1 plate", "1/2 plate", "3/4 plate", or "350 g serving". Recognises written
/// fractions and the words half / quarter / third. Grams-only or unrecognised
/// servings default to a full plate.
PlatePortion portionFromServing(String? serving) {
  final s = (serving ?? '').toLowerCase();
  if (s.isEmpty) return PlatePortion.full;

  // Explicit "n/m" fractions.
  final frac = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(s);
  if (frac != null) {
    final num = int.tryParse(frac.group(1)!) ?? 1;
    final den = int.tryParse(frac.group(2)!) ?? 1;
    if (den != 0) return _nearestPortion(num / den);
  }

  // Word forms.
  if (s.contains('three quarter') || s.contains('three-quarter')) {
    return PlatePortion.threeQuarters;
  }
  if (s.contains('two third') || s.contains('two-third')) {
    return PlatePortion.twoThirds;
  }
  if (s.contains('half')) return PlatePortion.half;
  if (s.contains('quarter')) return PlatePortion.threeQuarters;
  if (s.contains('third')) return PlatePortion.third;

  return PlatePortion.full;
}

/// Snaps an arbitrary 0–1 fraction to the nearest recognised [PlatePortion].
PlatePortion _nearestPortion(double f) {
  PlatePortion best = PlatePortion.full;
  var bestDelta = double.infinity;
  for (final p in PlatePortion.values) {
    final d = (p.fraction - f).abs();
    if (d < bestDelta) {
      bestDelta = d;
      best = p;
    }
  }
  return best;
}

/// A circular plate with a filled pie wedge representing [portion].
class PortionIcon extends StatelessWidget {
  const PortionIcon({
    super.key,
    required this.portion,
    this.size = 32,
    this.color,
  });

  final PlatePortion portion;
  final double size;

  /// Wedge colour; defaults to the app's primary pink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: portion.label,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PortionPainter(
            fraction: portion.fraction,
            fill: color ?? AppTheme.darkPink,
            ring: scheme.onSurface.withValues(alpha: 0.35),
            empty: scheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }
}

class _PortionPainter extends CustomPainter {
  _PortionPainter({
    required this.fraction,
    required this.fill,
    required this.ring,
    required this.empty,
  });

  final double fraction;
  final Color fill;
  final Color ring;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Empty plate background.
    canvas.drawCircle(center, radius, Paint()..color = empty);

    // Filled wedge, starting at 12 o'clock and sweeping clockwise.
    if (fraction > 0) {
      final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        true,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
    }

    // Plate rim.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PortionPainter old) =>
      old.fraction != fraction ||
      old.fill != fill ||
      old.ring != ring ||
      old.empty != empty;
}
