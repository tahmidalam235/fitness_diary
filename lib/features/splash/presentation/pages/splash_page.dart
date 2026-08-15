import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rotateAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
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
    _pulseAnimation = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.linear),
    );

    _entryController.forward();
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
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const _SplashBackground(),
          const _AthleticAccents(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 36,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, -8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/logo/fitness_diary_compact.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.appTitle.toUpperCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          l10n.appTagline.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _SplashLoader(rotateAnimation: _rotateAnimation),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Energetic, gradient-driven background. Uses the full hero gradient
/// vertically with two diagonal accent layers for depth and a subtle
/// moving "shine" via two large soft circles that drift off-screen.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.heroGradientVertical),
      child: _RadialGlow(),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: _blur(280, Colors.white.withValues(alpha: 0.22)),
        ),
        Positioned(
          bottom: -160,
          right: -100,
          child: _blur(360, const Color(0xFFEC4899).withValues(alpha: 0.30)),
        ),
        Positioned(
          top: 240,
          right: -120,
          child: _blur(220, const Color(0xFF22D3EE).withValues(alpha: 0.22)),
        ),
      ],
    );
  }

  Widget _blur(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size, spreadRadius: size / 6),
          ],
        ),
      ),
    );
  }
}

/// Abstract athletic accents — diagonal "speed lines" and dot accents
/// that reinforce the workout vibe without being a busy poster.
class _AthleticAccents extends StatelessWidget {
  const _AthleticAccents();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 80,
            left: -40,
            child: Transform.rotate(
              angle: -0.5,
              child: _line(width: 200, height: 3, opacity: 0.18),
            ),
          ),
          Positioned(
            top: 140,
            left: -10,
            child: Transform.rotate(
              angle: -0.5,
              child: _line(width: 140, height: 2, opacity: 0.12),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -50,
            child: Transform.rotate(
              angle: 0.5,
              child: _line(width: 220, height: 3, opacity: 0.16),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 0,
            child: Transform.rotate(
              angle: 0.5,
              child: _line(width: 160, height: 2, opacity: 0.12),
            ),
          ),
          // Floating dots that hint at motion / heart-rate
          Positioned(top: 220, left: 40, child: _dot(6, 0.4)),
          Positioned(top: 320, right: 50, child: _dot(4, 0.35)),
          Positioned(bottom: 220, left: 60, child: _dot(5, 0.3)),
          Positioned(bottom: 300, right: 80, child: _dot(7, 0.25)),
        ],
      ),
    );
  }

  Widget _line({required double width, required double height, required double opacity}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }

  Widget _dot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: opacity),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

/// A rotating dual-arc loader rendered with CustomPaint — feels sportier
/// than the stock CircularProgressIndicator and reinforces motion.
class _SplashLoader extends StatelessWidget {
  const _SplashLoader({required this.rotateAnimation});

  final Animation<double> rotateAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: AnimatedBuilder(
        animation: rotateAnimation,
        builder: (context, _) {
          return Transform.rotate(
            angle: rotateAnimation.value,
            child: CustomPaint(painter: _ArcPainter()),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.4,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
