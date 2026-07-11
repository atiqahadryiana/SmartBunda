/// SmartBunda reusable MD3 components.
///
/// These widgets encode the design-system specs (cards, buttons, section
/// headers, metric rings) so screens compose from consistent parts. Everything
/// reads from `Theme.of(context).colorScheme` and the [SmartBundaColors]
/// extension, so all components adapt to light & dark automatically.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_theme.dart';

// ════════════════════════════════════════════════════════════════════════
// HEADER BANNER
// ════════════════════════════════════════════════════════════════════════

/// Distinct page header banner — a pink-palette gradient block with rounded
/// bottom corners and on-container text, consistent across tab screens.
///
/// Adapts to light/dark automatically (built from `colorScheme`). Optionally
/// shows a leading [icon], a [subtitle], and a trailing [action] widget. By
/// default it pads for the status bar; pass `safeAreaTop: false` when placed
/// under an existing AppBar.
class SbHeaderBanner extends StatelessWidget {
  const SbHeaderBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.safeAreaTop = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final bool safeAreaTop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final onHeader = scheme.onPrimaryContainer;
    final topInset = safeAreaTop ? MediaQuery.of(context).padding.top : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.18),
              scheme.primaryContainer,
            ),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.m,
        topInset + AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.6),
                borderRadius: AppRadius.brM,
              ),
              child: Icon(icon, color: onHeader),
            ),
            const SizedBox(width: AppSpacing.s + 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, color: onHeader)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: text.bodyMedium?.copyWith(
                          color: onHeader.withValues(alpha: 0.8), height: 1.3)),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.s),
            action!,
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// CARDS
// ════════════════════════════════════════════════════════════════════════

/// Base SmartBunda card: rounded (20px), hairline outline, optional soft
/// shadow & tap handling. All other cards build on this.
class SbCard extends StatelessWidget {
  const SbCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.gradient,
    this.color,
    this.elevated = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : scheme.surface);

    final decoration = BoxDecoration(
      color: gradient == null ? surface : null,
      gradient: gradient,
      borderRadius: AppRadius.brL,
      border: Border.all(color: scheme.outlineVariant),
      boxShadow: elevated ? AppElevation.soft(scheme.primary) : null,
    );

    final content = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    final card = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            borderRadius: AppRadius.brL,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brL,
              child: content,
            ),
          );

    return Semantics(
      container: true,
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}

/// Section header: Poppins title + optional trailing action ("See all").
class SbSectionHeader extends StatelessWidget {
  const SbSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: text.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// A single nutrient stat (label + value/unit) with a thin progress bar.
class SbNutrientStat extends StatelessWidget {
  const SbNutrientStat({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    this.color,
  });

  final String label;
  final num value;
  final String unit;

  /// 0.0–1.0 of daily target.
  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final barColor = color ?? scheme.primary;
    return Semantics(
      label: '$label $value $unit, ${(progress * 100).round()} percent of goal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: text.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$value', style: text.titleMedium),
              TextSpan(
                  text: ' $unit',
                  style: text.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: AppSpacing.s),
          ClipRRect(
            borderRadius: AppRadius.brFull,
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-action tile used on the home dashboard (Scan Food / Log Meal / Log
/// Water). Tonal container, big rounded icon, label underneath.
class SbQuickAction extends StatelessWidget {
  const SbQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final container = tint ?? scheme.primaryContainer;
    final onContainer = tint == null
        ? scheme.onPrimaryContainer
        : ThemeData.estimateBrightnessForColor(tint!) == Brightness.dark
            ? Colors.white
            : AppTheme.primaryText;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brL,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: container,
                  borderRadius: AppRadius.brM,
                ),
                child: Icon(icon, color: onContainer, size: 26),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(label,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// METRIC RING  (circular progress for calories / hydration / nutrition score)
// ════════════════════════════════════════════════════════════════════════

/// Circular progress ring with a centred value & caption — used for Daily
/// Calories, Hydration goal, and Nutrition Score cards.
class SbMetricRing extends StatelessWidget {
  const SbMetricRing({
    super.key,
    required this.progress,
    required this.centerValue,
    required this.caption,
    this.size = 132,
    this.strokeWidth = 12,
    this.color,
    this.semanticLabel,
  });

  /// 0.0–1.0.
  final double progress;
  final String centerValue;
  final String caption;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ringColor = color ?? scheme.primary;
    return Semantics(
      label: semanticLabel ??
          '$caption: $centerValue, ${(progress * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                progress: progress.clamp(0, 1),
                color: ringColor,
                track: scheme.surfaceContainerHighest,
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerValue, style: text.headlineSmall),
                Text(caption,
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}

// ════════════════════════════════════════════════════════════════════════
// BUTTONS
// ════════════════════════════════════════════════════════════════════════

/// Filled button with a built-in loading state (spinner replaces the label and
/// the button is disabled while [loading] is true). Satisfies the
/// "disable button during async operations" touch rule.
class SbLoadingButton extends StatelessWidget {
  const SbLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
            ),
          )
        : (icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Text(label),
                ],
              ));

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      label: loading ? '$label, loading' : label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// A simple skeleton loader widget that shows a placeholder with a shimmer effect
/// using animated opacity to simulate loading state.
class SbSkeletonLoader extends StatefulWidget {
  const SbSkeletonLoader({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  State<SbSkeletonLoader> createState() => _SbSkeletonLoaderState();
}

class _SbSkeletonLoaderState extends State<SbSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius,
            shape: widget.shape,
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// STATUS PILL  (semantic chips: success / warning / info / on-track)
// ════════════════════════════════════════════════════════════════════════

enum SbStatus { success, warning, info, neutral }

/// Small tonal pill conveying status with both colour AND an icon/label, so
/// meaning is never carried by colour alone (colour-blind safe).
class SbStatusPill extends StatelessWidget {
  const SbStatusPill({
    super.key,
    required this.label,
    this.status = SbStatus.neutral,
    this.icon,
  });

  final String label;
  final SbStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<SmartBundaColors>()!;
    final (Color base, IconData defaultIcon) = switch (status) {
      SbStatus.success => (semantic.success, Icons.check_circle_rounded),
      SbStatus.warning => (semantic.warning, Icons.warning_amber_rounded),
      SbStatus.info => (semantic.info, Icons.info_rounded),
      SbStatus.neutral => (scheme.onSurfaceVariant, Icons.circle_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        borderRadius: AppRadius.brFull,
        border: Border.all(color: base.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? defaultIcon, size: 14, color: base),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: base, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
