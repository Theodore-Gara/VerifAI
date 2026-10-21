import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';
import 'package:verifai/shared/widgets/hub_tile.dart';

/// Practice — the hub for doing: the recommended task first, then the skill
/// scenarios and the practice tools that used to live in the drawer.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scenarios = <HubEntry>[
      const HubEntry(
        title: 'Verification',
        subtitle: 'Catch AI mistakes and fix them',
        icon: Icons.shield_rounded,
        route: '/verification',
      ),
      const HubEntry(
        title: 'AI Judgement',
        subtitle: 'Decide when AI should or shouldnt be used',
        icon: Icons.psychology_rounded,
        route: '/judgement',
      ),
      const HubEntry(
        title: 'Risk & Governance',
        subtitle: 'Spot privacy bias and compliance risks',
        icon: Icons.gavel_rounded,
        route: '/risk-governance',
      ),
      const HubEntry(
        title: 'Interview practice',
        subtitle: 'Work through interview questions',
        icon: Icons.question_answer_rounded,
        route: '/interview',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Text(
          'Practice',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Menu',
            onPressed: openVerifaiNavigationDrawer,
            icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
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
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              dockClearance(context),
            ),
            children: [
              Text(
                'Do the work',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'One scenario at a time, then check what changed.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const HubSectionTitle('Skill scenarios'),
              for (final entry in scenarios) HubTile(entry: entry),
              const HubSectionTitle('Practice tools'),
              const HubTile(
                entry: HubEntry(
                  title: 'Verification Studio',
                  subtitle: 'Paste AI output and get a structured critique',
                  icon: Icons.fact_check_rounded,
                  route: '/verification-studio',
                ),
              ),
              const HubTile(
                entry: HubEntry(
                  title: 'Industry practice cases',
                  subtitle: 'Read a workplace case and record the decision',
                  icon: Icons.business_center_rounded,
                  route: '/industry-practice',
                ),
              ),
              const HubTile(
                entry: HubEntry(
                  title: 'Task history',
                  subtitle: 'Every graded attempt, with the feedback',
                  icon: Icons.history_rounded,
                  route: '/task-history',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
