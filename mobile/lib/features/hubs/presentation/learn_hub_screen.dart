import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/hub_tile.dart';

/// Learn — the hub for everything the learner reads, studies or is assessed on.
///
/// The old layout spread these across a 13-link drawer, a "Track" tab and
/// several full-screen routes; the bottom dock now carries five areas and each
/// one gathers its own destinations here.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Text(
          'Learn',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ambientCyan,
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              110,
            ),
            children: [
              Text(
                'Build the knowledge',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lessons, scenarios and capstones — read it, practise it, prove it.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const HubSectionTitle('Curriculum'),
              const HubTile(
                entry: HubEntry(
                  title: 'AI Lab lessons',
                  subtitle: 'Textbook lessons with chapters, topics and sources',
                  icon: Icons.science_rounded,
                  route: '/ai-lab/lessons',
                ),
              ),
              const HubTile(
                entry: HubEntry(
                  title: 'Recall practice',
                  subtitle: 'Quick questions drawn from each lesson',
                  icon: Icons.quiz_rounded,
                  route: '/ai-lab/practice',
                ),
              ),
              const HubTile(
                entry: HubEntry(
                  title: 'Capstone assessments',
                  subtitle: 'Timed, scenario-based papers marked against a rubric',
                  icon: Icons.workspace_premium_rounded,
                  route: '/ai-lab/assessments',
                ),
              ),
              const HubSectionTitle('Your path'),
              const HubTile(
                entry: HubEntry(
                  title: 'Skill roadmap',
                  subtitle: 'Where you are in your track and what comes next',
                  icon: Icons.alt_route_rounded,
                  route: '/track',
                ),
              ),
              const HubTile(
                entry: HubEntry(
                  title: 'Ask Vera',
                  subtitle: 'A study partner that knows your progress',
                  icon: Icons.auto_awesome_rounded,
                  route: '/assistant',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
