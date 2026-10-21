import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';

/// Home. Leads with the one thing the learner can do next — a recommended task,
/// their XP progress and their assessed dimensions — then the exploration grid.
/// Everything here comes from a single `GET /api/dashboard` request.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(user?.name),
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user?.trackName ?? 'Choose your specialization',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          // Secondary navigation: the dock is primary, so the full index sits
          // here at low emphasis instead of taking every screen's leading slot.
          IconButton(
            tooltip: 'All sections',
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: openVerifaiNavigationDrawer,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient background glows
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
          Positioned(
            top: 240,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ambientGreen,
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              try {
                // Await so the spinner covers the reload. A failure is already
                // rendered by AsyncErrorView with its own retry action, so it
                // must not escape the pull gesture as an unhandled error.
                await ref.read(dashboardProvider.future);
              } on Object {
                // Displayed by the error branch above.
              }
            },
            child: dashboardAsync.when(
              data: (data) => _buildDashboard(data),
              loading: () => _buildShimmer(),
              error: (error, stackTrace) => AsyncErrorView(
                error: error,
                fallbackMessage: 'Failed to load dashboard. Pull to refresh.',
                onRetry: () => reconnectApp(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final first = (name ?? '').trim().split(' ').first;
    return first.isEmpty ? '$part.' : '$part, $first';
  }

  Future<void> _startNextTask(DailyTask task) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await context.push('/task-run',
          extra: TaskRunArgs(task, practice: task.isRepeat));
      // The attempt may have changed XP, readiness and the next task.
      ref.invalidate(dashboardProvider);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _buildDashboard(DashboardData data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        dockClearance(context) - 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readiness score at top
          _buildReadinessCard(data),
          const SizedBox(height: AppSpacing.md),
          // Streak and tasks
          Row(
            children: [
              Expanded(
                child: _statTile(
                  value: '${data.streakDays}',
                  label: 'Day streak',
                  semanticsLabel: '${data.streakDays} day streak',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _statTile(
                  value: '${data.completedTasks}',
                  label: 'Tasks completed',
                  semanticsLabel: '${data.completedTasks} tasks completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Next task
          _buildNextAction(data),
          const SizedBox(height: AppSpacing.md),
          // Keep going section
          _buildQuickLaunches(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Next action — the core loop, on the first screen.
  // ---------------------------------------------------------------------------
  Widget _buildNextAction(DashboardData data) {
    final task = data.dailyTask;

    if (task == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nothing lined up yet',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'New scenarios land regularly. Try a practice case or a lesson '
              'while you wait for the next one.',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: VerifAIButton(
                    label: 'Open AI Lab',
                    onPressed: () => context.push('/ai-lab'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: VerifAIButton(
                    label: 'Practice cases',
                    variant: VerifAIButtonVariant.secondary,
                    onPressed: () => context.push('/industry-practice'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Next task: ${task.title}. '
          '${task.dimension}, ${task.difficulty ?? 'medium'} difficulty. '
          '${task.isRepeat ? 'Practice again.' : 'Not attempted yet.'}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.primaryNavy.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  task.isRepeat ? 'PRACTICE AGAIN' : 'YOUR NEXT TASK',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 11.5,
                  ),
                ),
                const Spacer(),
                if (task.difficulty != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      task.difficulty!.toUpperCase(),
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.dimension,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              label: task.isRepeat
                  ? 'Practise ${task.title} again'
                  : 'Start ${task.title}',
              child: VerifAIButton(
                label: task.isRepeat ? 'Practise again' : 'Start task',
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: _starting,
                onPressed: _starting ? null : () => _startNextTask(task),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard(DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: 'AI readiness score ${data.overallScore} out of 100, '
                '${data.tier ?? 'Novice'} tier',
            child: ExcludeSemantics(
              child: ScoreRing(
                score: data.overallScore,
                size: 104,
                strokeWidth: 10,
                tierLabel: data.tier,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI readiness',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'How consistently you verify AI output across the assessed '
                  'skills.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const ShimmerLoader.card(height: 160),
        const SizedBox(height: AppSpacing.md),
        ShimmerLoader(
          height: 70,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ShimmerLoader(
                height: 70,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ShimmerLoader(
                height: 70,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader.card(height: 200),
      ],
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required String semanticsLabel,
    bool accent = false,
  }) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: accent
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color:
                      accent ? AppColors.accentGreen : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLaunches(BuildContext context) {
    final gridItems =
        <({String title, String subtitle, IconData icon, String route})>[
      (
        title: 'AI Assistant',
        subtitle: 'Ask Vera',
        icon: Icons.auto_awesome_rounded,
        route: '/assistant',
      ),
      (
        title: 'Learn',
        subtitle: 'Lessons & capstones',
        icon: Icons.menu_book_rounded,
        route: '/learn',
      ),
      (
        title: 'Practice',
        subtitle: 'Skills & scenarios',
        icon: Icons.play_circle_outline_rounded,
        route: '/practice',
      ),
      (
        title: 'Rewards',
        subtitle: 'XP & milestones',
        icon: Icons.workspace_premium_rounded,
        route: '/rewards',
      ),
      (
        title: 'Wellbeing',
        subtitle: 'Check in, reflect',
        icon: Icons.spa_rounded,
        route: '/wellness',
      ),
      (
        title: 'History',
        subtitle: 'Past attempts',
        icon: Icons.history_rounded,
        route: '/task-history',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keep going',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Build confidence. Verify before you rely.',
          style: AppTypography.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            // Fixed extent instead of an aspect ratio: the tiles keep their
            // height as the OS text scale grows, so labels wrap instead of
            // overflowing the card.
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final item = gridItems[index];
            return Semantics(
              button: true,
              label: '${item.title}. ${item.subtitle}.',
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  // Hub routes are shell tabs: switch the dock in place. `go`-ing
                  // to a sibling shell route would mount a second shell and
                  // collide on the shared scaffold global key.
                  onTap: () {
                    final tab = shellTabIndex[item.route];
                    if (tab != null) {
                      switchShellTab(tab);
                    } else {
                      context.push(item.route);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primaryNavy,
                              size: 18,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.textTheme.bodySmall?.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
