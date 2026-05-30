import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/screens/get_started_screen.dart';
import 'package:smartbunda/screens/home_screen.dart';
import 'package:smartbunda/screens/login_screen.dart';

class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key});

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final Animation<double> _markScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _markScale = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutBack,
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _introController.forward();
    _openNextScreen();
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openNextScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    AppUser? user;
    try {
      user = await ref
          .read(authStateProvider.future)
          .timeout(const Duration(milliseconds: 1200));
    } on TimeoutException {
      user = null;
    } catch (_) {
      user = null;
    }
    if (!mounted) return;

    final next = user == null
        ? await _firstSignedOutScreen()
        : HomeScreen(initialUser: user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_FadeRoute(builder: (_) => next));
  }

  Future<Widget> _firstSignedOutScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen =
          prefs.getBool(GetStartedScreen.seenPreferenceKey) ?? false;
      return hasSeen ? const LoginScreen() : const GetStartedScreen();
    } catch (_) {
      return const GetStartedScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF111827) : Colors.white;
    final topWash = dark ? const Color(0xFF1F2937) : const Color(0xFFFFE8F1);
    final midWash = dark ? const Color(0xFF183B4A) : const Color(0xFFE7F6FF);
    final bottomWash = dark ? const Color(0xFF2D2342) : const Color(0xFFF0E8FF);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topWash, background, midWash, bottomWash],
            stops: const [0, 0.36, 0.68, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _SplashPattern()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _markScale,
                              child: _SmartbundaLogo(pulse: _pulseController),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'SMARTBUNDA',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: dark
                                        ? Colors.white
                                        : const Color(0xFF253144),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Smart Nutrition & Health Companion',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: dark
                                        ? Colors.white.withAlpha(190)
                                        : const Color(0xFF59677D),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            const Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _SignalPill(
                                  icon: Icons.favorite_outline,
                                  label: 'Care',
                                  color: Color(0xFFE86D9B),
                                ),
                                _SignalPill(
                                  icon: Icons.restaurant_outlined,
                                  label: 'Nutrition',
                                  color: Color(0xFF23A6A6),
                                ),
                                _SignalPill(
                                  icon: Icons.auto_awesome_outlined,
                                  label: 'AI',
                                  color: Color(0xFF8A7CF6),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          _GlowingLoader(
                            animation: _pulseController,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Preparing your care space',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: dark
                                          ? Colors.white.withAlpha(160)
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartbundaLogo extends StatelessWidget {
  const _SmartbundaLogo({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 0.18 + (pulse.value * 0.16);
        return Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF8DB6),
                Color(0xFFA78BFA),
                Color(0xFF4ECBC4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8DB6).withAlpha((glow * 255).round()),
                blurRadius: 38,
                spreadRadius: 2,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: const Color(0xFF4ECBC4).withAlpha((glow * 180).round()),
                blurRadius: 44,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _LogoPainter(),
            child: const Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = Colors.white.withAlpha(225)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final softFill = Paint()
      ..color = Colors.white.withAlpha(38)
      ..style = PaintingStyle.fill;

    final mother = Offset(size.width * 0.39, size.height * 0.47);
    final child = Offset(size.width * 0.62, size.height * 0.55);

    canvas.drawCircle(mother, size.width * 0.105, softFill);
    canvas.drawCircle(child, size.width * 0.075, softFill);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.47, size.height * 0.67),
        radius: size.width * 0.25,
      ),
      math.pi * 1.08,
      math.pi * 0.86,
      false,
      white,
    );
    canvas.drawCircle(Offset(size.width * 0.73, size.height * 0.32), 4, white);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.44), 3, white);
    canvas.drawCircle(Offset(size.width * 0.66, size.height * 0.28), 3, white);
    canvas.drawLine(
      Offset(size.width * 0.73, size.height * 0.32),
      Offset(size.width * 0.78, size.height * 0.44),
      white,
    );
    canvas.drawLine(
      Offset(size.width * 0.73, size.height * 0.32),
      Offset(size.width * 0.66, size.height * 0.28),
      white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(24) : Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: dark ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlowingLoader extends StatelessWidget {
  const _GlowingLoader({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (animation.value + index * 0.22) % 1;
            final scale = 0.74 + (math.sin(phase * math.pi) * 0.38);
            return Container(
              width: 42,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Color.lerp(
                  color,
                  const Color(0xFF4ECBC4),
                  index / 2,
                )!
                    .withAlpha((120 + 95 * scale).round()),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((35 + 45 * scale).round()),
                    blurRadius: 12 * scale,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _SplashPattern extends StatelessWidget {
  const _SplashPattern();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _SplashPatternPainter());
  }
}

class _SplashPatternPainter extends CustomPainter {
  const _SplashPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shapePaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF23A6A6).withAlpha(38);

    shapePaint.color = const Color(0xFFFF8DB6).withAlpha(40);
    canvas.drawCircle(
        Offset(size.width * 0.08, size.height * 0.18), 56, shapePaint);
    shapePaint.color = const Color(0xFF8A7CF6).withAlpha(34);
    canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.24), 72, shapePaint);
    shapePaint.color = const Color(0xFF4ECBC4).withAlpha(34);
    canvas.drawCircle(
        Offset(size.width * 0.14, size.height * 0.82), 88, shapePaint);

    final wave = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.70,
        size.width * 0.42,
        size.height * 0.86,
        size.width * 0.66,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.72,
        size.width * 0.94,
        size.height * 0.76,
        size.width,
        size.height * 0.72,
      );
    canvas.drawPath(wave, linePaint);

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8A7CF6).withAlpha(80);
    final nodes = [
      Offset(size.width * 0.22, size.height * 0.31),
      Offset(size.width * 0.30, size.height * 0.23),
      Offset(size.width * 0.39, size.height * 0.28),
      Offset(size.width * 0.72, size.height * 0.68),
      Offset(size.width * 0.80, size.height * 0.61),
      Offset(size.width * 0.88, size.height * 0.68),
    ];
    for (var i = 0; i < nodes.length; i++) {
      canvas.drawCircle(nodes[i], 3.4, nodePaint);
      if (i % 3 != 2) {
        canvas.drawLine(nodes[i], nodes[i + 1], linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FadeRoute extends PageRouteBuilder<void> {
  _FadeRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
        );
}
