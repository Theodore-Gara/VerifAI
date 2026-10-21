import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/features/verification/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/daily_task_card.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Dedicated Verification flow: one card per difficulty, rotating exhausted
/// bands as practice.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  void _startTask(DailyTask task) {
    HapticFeedback.mediumImpact();
    context.push('/task-run',
        extra: TaskRunArgs(task, practice: task.isRepeat));
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(verificationTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Verification',
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
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientCyan,
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(verificationTasksProvider);
                try {
                  // Await so the spinner covers the reload.
                  await ref.read(verificationTasksProvider.future);
                } on Object {
                  // Rendered by the error branch below.
                }
              },
              child: tasksAsync.when(
                data: _buildTasks,
                loading: _buildShimmer,
                error: (error, stackTrace) => AsyncErrorView(
                  error: error,
                  fallbackMessage: 'Failed to load your tasks.',
                  onRetry: () => reconnectApp(ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasks(List<DailyTask> tasks) {
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'All caught up!',
            message:
                'No verification tasks right now. Check back tomorrow for your next challenge.',
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification tasks',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final task in tasks) ...[
            DailyTaskCard(
              task: task,
              onStart: () => _startTask(task),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        ShimmerLoader(height: 28, width: 180),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader.card(height: 200),
      ],
    );
  }
}
