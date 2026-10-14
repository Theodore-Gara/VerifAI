import 'dart:async';

import 'package:flutter/material.dart';
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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

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
    } else {
      authState.when(
        unauthenticated: () => context.go('/login'),
        authenticated: (user, token) => context.go('/dashboard'),
        needsOnboarding: (user, token) => context.go('/industry-select'),
        loading: () => context.go('/login'),
      );
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentGreen,
              AppColors.accentCyan,
              AppColors.accentGreen,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/logoalldarktrans.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.verified_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'VerifAI',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryNavy.withValues(alpha: 0.9),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'AI assists. Humans verify.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryNavy.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
