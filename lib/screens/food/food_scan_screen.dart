import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/screens/log/meal_log_actions.dart';

class FoodScanScreen extends ConsumerWidget {
  const FoodScanScreen({super.key});

  static const routeName = '/food-scan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceBase,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ScanHero(strings: strings, ref: ref),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                const SizedBox(height: 20),
                _ActionButtons(strings: strings, ref: ref),
                const SizedBox(height: 20),
                _HowItWorksCard(strings: strings),
                const SizedBox(height: 14),
                _ScanTipBanner(strings: strings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero scan zone ────────────────────────────────────────────────────────────

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.strings, required this.ref});

  final AppStrings strings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    Material(
                      color: Colors.white.withValues(alpha: 0.863),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back,
                            color: AppTheme.darkPink,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.863),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: AppTheme.darkPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('Meal Scanner'),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryText,
                                  ),
                        ),
                        Text(
                          strings.t('AI-powered food recognition'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondaryText,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── scan zone ────────────────────────────────────────────────────
            _ScanZone(strings: strings, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _ScanZone extends StatelessWidget {
  const _ScanZone({required this.strings, required this.ref});

  final AppStrings strings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MealLogActions.captureMeal(
        context,
        ref,
        source: ImageSource.camera,
      ),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryPink.withValues(alpha: 0.392),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withValues(alpha: 0.118),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // corner brackets
            ..._ScanCorners.all,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkPink.withValues(alpha: 0.275),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.t('Tap to scan food'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t('Point camera at a dish for AI detection'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Corner bracket decorations for the scan zone
class _ScanCorners {
  static const _size = 22.0;
  static const _thick = 3.0;
  static const _r = 6.0;
  static const _pad = 12.0;

  static List<Widget> get all => [
        Positioned(
          top: _pad,
          left: _pad,
          child: _corner(top: true, left: true),
        ),
        Positioned(
          top: _pad,
          right: _pad,
          child: _corner(top: true, left: false),
        ),
        Positioned(
          bottom: _pad,
          left: _pad,
          child: _corner(top: false, left: true),
        ),
        Positioned(
          bottom: _pad,
          right: _pad,
          child: _corner(top: false, left: false),
        ),
      ];

  static Widget _corner({required bool top, required bool left}) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _CornerPainter(
          top: top,
          left: left,
          color: AppTheme.darkPink,
          thick: _thick,
          radius: _r,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thick,
    required this.radius,
  });

  final bool top;
  final bool left;
  final Color color;
  final double thick;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final xDir = left ? 1.0 : -1.0;
    final yDir = top ? 1.0 : -1.0;

    final path = Path()
      ..moveTo(x, y + yDir * (size.height * 0.6))
      ..lineTo(x, y + yDir * radius)
      ..arcToPoint(
        Offset(x + xDir * radius, y),
        radius: Radius.circular(radius),
        clockwise: left == top,
      )
      ..lineTo(x + xDir * (size.width * 0.6), y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.strings, required this.ref});

  final AppStrings strings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _PrimaryActionButton(
            icon: Icons.camera_alt,
            label: strings.t('Camera'),
            onTap: () => MealLogActions.captureMeal(
              context,
              ref,
              source: ImageSource.camera,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _SecondaryActionButton(
            icon: Icons.photo_library_outlined,
            label: strings.t('Gallery'),
            onTap: () => MealLogActions.captureMeal(
              context,
              ref,
              source: ImageSource.gallery,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryPink.withValues(alpha: 0.078),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF8BBD0)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppTheme.darkPink),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkPink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Result info cards ─────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8BBD0)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 0.047),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.blushGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.darkPink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strings.t('How it works'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Step(
            number: '1',
            title: strings.t('Capture or upload'),
            body: strings.t(
                'Take a clear photo of your meal, or pick one from gallery.'),
          ),
          const SizedBox(height: 12),
          _Step(
            number: '2',
            title: strings.t('AI detects the dish'),
            body: strings.t(
                'The photo is sent to our AI scanner, which identifies the food and shows the best matches with confidence scores.'),
          ),
          const SizedBox(height: 12),
          _Step(
            number: '3',
            title: strings.t('Verify and save'),
            body: strings.t(
                "If several foods are found, tick the ones that are correct. Set the portion and add it to your daily log."),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanTipBanner extends StatelessWidget {
  const _ScanTipBanner({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.blushGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.235)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            color: AppTheme.darkPink,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.t(
                'Best results: single dish, good lighting, close-up shot. Avoid mixed plates.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryText,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
