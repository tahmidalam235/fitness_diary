import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_spacing.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(AppDurations.splash, _navigateToDashboard);
  }

  void _navigateToDashboard() {
    if (!mounted) {
      return;
    }
    context.go(RoutePaths.dashboard);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _SplashBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircularLoader(),
                SizedBox(height: AppSpacing.xl),
                _SplashLogo(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Edge-to-edge smooth red/pink gradient — the exact tonal range of the
/// reference: soft pink at the top, vibrant red through the middle,
/// fading to a deep, rich red at the bottom.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCA5A5), // red-300  (soft pink, top)
            Color(0xFFF87171), // red-400
            Color(0xFFEF4444), // red-500  (vibrant red, middle)
            Color(0xFFB91C1C), // red-600
            Color(0xFF7F1D1D), // red-800  (deep dark red, bottom)
          ],
          stops: [0.0, 0.20, 0.50, 0.78, 1.0],
        ),
      ),
    );
  }
}

/// Big, centered logo with a soft drop shadow. Sized as a fraction of
/// screen width so it reads as the main subject on any device. Wrapped
/// in its own FadeTransition + ScaleTransition + gentle pulse so the
/// entry animation still feels alive.
class _SplashLogo extends StatefulWidget {
  const _SplashLogo();

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Logo size: ~78% of the longer screen edge so the diary fills
        // roughly the same proportion of the screen as the reference
        // (around 75-80% of screen height on portrait phones). Capped
        // so it never gets cartoonishly large on tablets and never goes
        // below a minimum readable size.
        final longSide = constraints.maxWidth > constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final size = (longSide * 0.78).clamp(360.0, 780.0);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 24),
                    ),
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.20),
                      blurRadius: 80,
                      spreadRadius: 8,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo/fitness_diary_splash.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rotating circular loader with a soft white "track" ring and a bright
/// orange → pink → red gradient arc that sweeps around it. Matches the
/// reference style: subtle background ring with an energetic colored
/// arc on top.
class _CircularLoader extends StatefulWidget {
  const _CircularLoader();

  @override
  State<_CircularLoader> createState() => _CircularLoaderState();
}

class _CircularLoaderState extends State<_CircularLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1.4s per full rotation — fast enough to feel alive, slow enough
    // to read as deliberate motion.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.141592653589793,
            child: CustomPaint(
              painter: _CircularLoaderPainter(),
              size: const Size(72, 72),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the circular loader.
///
/// Layered composition (back to front):
///   1. Soft white background ring — 60% opacity, gives the loader a
///      visible "track" on the red gradient.
///   2. Bright gradient arc — 270° sweep across orange → pink → red,
///      matches the warm palette of the reference image.
class _CircularLoaderPainter extends CustomPainter {
  static const double _strokeWidth = 7.0;
  static const double _trackOpacity = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;

    // 1. Background track — soft white ring at reduced opacity.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: _trackOpacity);
    canvas.drawCircle(center, radius, track);

    // 2. Gradient arc — bright orange → pink → red sweep.
    // Sweep angle: 270° so a quarter of the ring stays empty, giving
    // the loader a sense of direction (matches the reference).
    const sweep = 3.0 * 3.141592653589793 / 2; // 270°
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Use a sweep gradient that rotates with the painter (since the
    // whole widget is rotated by Transform.rotate). This way the
    // gradient anchors to the canvas, not to the rotation.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * 3.141592653589793,
        colors: const [
          Color(0xFFFFA726), // orange-400 (tail)
          Color(0xFFFF7043), // deep orange
          Color(0xFFEF5350), // red-400
          Color(0xFFEC407A), // pink-400 (head)
          Color(0xFFFFA726), // back to orange so the gradient loops
        ],
        stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
      ).createShader(rect);

    // Start the arc near the top (12 o'clock) — a small negative angle
    // moves the start point counter-clockwise so the bright head sits
    // at the leading edge of the sweep.
    canvas.drawArc(rect, -1.5708, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
