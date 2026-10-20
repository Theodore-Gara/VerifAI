import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _startWelcomeAndNavigate();
  }

  Future<void> _startWelcomeAndNavigate() async {
    // Wake the backend (Render free tier sleeps when idle) while the splash is
    // showing, so the first real request - especially an AI call - is not the
    // one that has to wait ~50s for the instance to boot.
    unawaited(_warmUpBackend());
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState == null) {
      context.go('/login');
      return;
    }
    authState.when(
      unauthenticated: () => context.go('/login'),
      authenticated: (user, token) => context.go('/dashboard'),
      needsOnboarding: (user, token) => context.go('/industry-select'),
      loading: () => context.go('/login'),
    );
  }

  Future<void> _warmUpBackend() async {
    try {
      await ref.read(apiClientProvider).ping();
    } catch (_) {
      // Best effort: a cold or unreachable backend is handled by each screen.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.primaryDark,
          body: Stack(
            children: [
              const Positioned.fill(child: _LuxuryParticleField()),
              Positioned(
                top: -120,
                right: -100,
                child:
                    _ambient(300, AppColors.accentGreen.withValues(alpha: .12)),
              ),
              Positioned(
                bottom: -145,
                left: -105,
                child: _ambient(330, AppColors.gold.withValues(alpha: .10)),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logodarktrans.png',
                            width: 220,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.verified_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Text(
                            'AI assists. Humans verify.',
                            style: TextStyle(
                              color: Color(0xFFD5B779),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .55,
                            ),
                          ),
                          const SizedBox(height: 42),
                          SizedBox(
                            width: 76,
                            child: Divider(
                              color: AppColors.gold.withValues(alpha: .7),
                              thickness: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'THINK CLEARLY. VERIFY WITH CONFIDENCE.',
                            style: TextStyle(
                              color: Color(0xFFB8C3BA),
                              fontSize: 9,
                              letterSpacing: 1.7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  Widget _ambient(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _LuxuryParticleField extends StatelessWidget {
  const _LuxuryParticleField();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _LuxuryParticlePainter(),
          size: Size.infinite,
        ),
      );
}

class _LuxuryParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(size.width * .13, size.height * .19),
      Offset(size.width * .82, size.height * .14),
      Offset(size.width * .73, size.height * .27),
      Offset(size.width * .19, size.height * .68),
      Offset(size.width * .86, size.height * .76),
      Offset(size.width * .27, size.height * .84),
      Offset(size.width * .62, size.height * .91),
      Offset(size.width * .91, size.height * .42),
      Offset(size.width * .08, size.height * .43),
      Offset(size.width * .46, size.height * .11),
      Offset(size.width * .55, size.height * .72),
      Offset(size.width * .36, size.height * .31),
    ];
    for (var i = 0; i < points.length; i++) {
      final radius = i % 4 == 0 ? 1.8 : .9;
      final paint = Paint()
        ..color = AppColors.gold.withValues(alpha: i % 3 == 0 ? .68 : .28);
      canvas.drawCircle(points[i], radius, paint);
      if (i % 4 == 0) {
        final glow = Paint()
          ..color = AppColors.gold.withValues(alpha: .12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(points[i], 5, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
