import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// Shared step indicator for the two-step first-run onboarding
/// (1: choose an industry, 2: the welcome tour).
///
/// Both onboarding screens render this so the learner sees one continuous
/// journey rather than two screens that disagree about how many steps exist.
class OnboardingStepBar extends StatelessWidget {
  const OnboardingStepBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// 1-based index of the step the learner is on.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final active = stepNumber <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: stepNumber == totalSteps ? 0 : 7),
            decoration: BoxDecoration(
              // The palette's border colour, so the unfilled segment follows
              // the active theme instead of staying light grey in dark mode.
              color: active ? AppColors.accentGreen : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}

/// "STEP 1 OF 2" label, the same wording on every onboarding screen.
class OnboardingStepLabel extends StatelessWidget {
  const OnboardingStepLabel({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.color,
  });

  final int currentStep;
  final int totalSteps;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'STEP $currentStep OF $totalSteps',
      style: AppTypography.textTheme.labelSmall?.copyWith(
        color: color ?? AppColors.accentGreen,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// The gradient hero used at the top of both onboarding screens.
///
/// Shared so step 1 and step 2 read as one system rather than two designs
/// that happen to sit next to each other.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryFill, AppColors.greenFill],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFDCE8E1),
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
