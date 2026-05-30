import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  static const routeName = '/get-started';
  static const seenPreferenceKey = 'hasSeenGetStarted';

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController _backgroundController;
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.favorite,
      title: 'Welcome to SmartBunda',
      body:
          'A warm space for pregnancy nutrition, health tracking, and connected family care.',
      accent: AppTheme.darkPink,
    ),
    _OnboardingSlide(
      icon: Icons.center_focus_strong_outlined,
      title: 'AI Food Recognition',
      body:
          'Snap a photo of your meal — our AI identifies Malaysian dishes and logs nutrition instantly.',
      accent: AppTheme.accentPink,
    ),
    _OnboardingSlide(
      icon: Icons.monitor_heart_outlined,
      title: 'Your Health, Tracked',
      body:
          'Monitor daily nutrition goals, hydration, and pregnancy milestones all in one place.',
      accent: AppTheme.healthcareTeal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndOpenLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GetStartedScreen.seenPreferenceKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _markSeenAndOpenLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return CustomPaint(
            painter: _PinkDynamicBackgroundPainter(
              progress: _backgroundController.value,
              surface: scheme.surface,
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    return _SlidePage(slide: _slides[index]);
                  },
                ),
              ),
              _PageDots(count: _slides.length, activeIndex: _page),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
                child: GradientButton(
                  onPressed: _next,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _page == _slides.length - 1 ? 'Get started' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _page == _slides.length - 1
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinkDynamicBackgroundPainter extends CustomPainter {
  const _PinkDynamicBackgroundPainter({
    required this.progress,
    required this.surface,
  });

  final double progress;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shift = math.sin(progress * math.pi * 2) * 0.18;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + shift, -1),
        end: Alignment(1 - shift, 1),
        colors: [
          const Color(0xFFFFD9E8),
          Color.alphaBlend(const Color(0xFFFF8DB6).withAlpha(34), surface),
          const Color(0xFFFBE9FF),
          const Color(0xFFFFEEF5),
        ],
        stops: const [0, 0.38, 0.72, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.14 + 0.04 * math.sin(progress * math.pi * 2)),
        size.height * (0.18 + 0.03 * math.cos(progress * math.pi * 2)),
      ),
      radius: size.shortestSide * 0.28,
      color: const Color(0xFFFF8DB6).withAlpha(54),
    );
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.86 + 0.04 * math.cos(progress * math.pi * 2)),
        size.height * (0.30 + 0.04 * math.sin(progress * math.pi * 2)),
      ),
      radius: size.shortestSide * 0.24,
      color: const Color(0xFFE86D9B).withAlpha(44),
    );
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.24 + 0.05 * math.cos(progress * math.pi * 2)),
        size.height * (0.82 + 0.03 * math.sin(progress * math.pi * 2)),
      ),
      radius: size.shortestSide * 0.30,
      color: const Color(0xFFFFB4CD).withAlpha(48),
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFC24879).withAlpha(38);
    final wave = Path()
      ..moveTo(
          0, size.height * (0.72 + 0.025 * math.sin(progress * math.pi * 2)))
      ..cubicTo(
        size.width * 0.28,
        size.height * (0.64 + 0.035 * math.cos(progress * math.pi * 2)),
        size.width * 0.48,
        size.height * (0.82 + 0.025 * math.sin(progress * math.pi * 2)),
        size.width * 0.72,
        size.height * (0.75 + 0.030 * math.cos(progress * math.pi * 2)),
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.70,
        size.width,
        size.height * 0.77,
        size.width,
        size.height * 0.70,
      );
    canvas.drawPath(wave, wavePaint);
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PinkDynamicBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.surface != surface;
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 170);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.68,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WelcomeMark(accent: slide.accent, icon: slide.icon),
            const SizedBox(height: 30),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF253144),
                    letterSpacing: 0,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: muted,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 28),
            _FeaturePill(
              icon: slide.icon,
              label: _labelFor(slide.icon),
              color: slide.accent,
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(IconData icon) {
    if (icon == Icons.restaurant_menu_outlined) return 'Nutrition';
    if (icon == Icons.auto_awesome_outlined) return 'Smart AI';
    return 'Health';
  }
}

class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark({
    required this.accent,
    required this.icon,
  });

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 185),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 35),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        ),
        Container(
          width: 138,
          height: 138,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF8DB6),
                Color(0xFFA78BFA),
                Color(0xFF4ECBC4),
              ],
            ),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 48),
        ),
        Positioned(
          right: 12,
          bottom: 30,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 20),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: accent),
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 210),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF374151),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFD8CFE7),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
