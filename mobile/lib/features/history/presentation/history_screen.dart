import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/history/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Task History — a unified timeline of tasks, practice activities and capstones.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Task History',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [ShimmerLoader(height: 64), SizedBox(height: AppSpacing.sm), ShimmerLoader(height: 64), SizedBox(height: AppSpacing.sm), ShimmerLoader(height: 64)],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load your history.',
          onRetry: () => ref.invalidate(historyProvider),
        ),
        data: (entries) => entries.isEmpty
            ? const EmptyState(
                icon: Icons.history_rounded,
                title: 'Nothing here yet',
                message: 'Complete a task, practice question or capstone to build your history.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
                    AppSpacing.screenPadding, AppSpacing.xxl),
                children: [for (final e in entries) _tile(e)],
              ),
      ),
    );
  }

  Widget _tile(HistoryEntry e) {
    final (icon, color) = switch (e.type) {
      'capstone' => (Icons.workspace_premium_rounded, AppColors.primaryNavy),
      'activity' => (Icons.quiz_outlined, AppColors.accentCyan),
      _ => (Icons.task_alt_rounded, AppColors.accentGreen),
    };
    final trailing = e.score != null
        ? '${e.score}%'
        : (e.passed == true ? 'Done' : (e.passed == false ? 'Attempted' : '—'));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primaryNavy, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                  const SizedBox(height: 3),
                  Text('${_label(e)} · ${_date(e.createdAt)}${e.xpEarned > 0 ? ' · +${e.xpEarned} XP' : ''}',
                      style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(trailing,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: e.passed == false ? AppColors.goldDark : AppColors.primaryNavy)),
          ],
        ),
      ),
    );
  }

  String _label(HistoryEntry e) => switch (e.type) {
        'capstone' => 'Capstone',
        'activity' => 'Practice',
        _ => 'Task${e.feature != null ? ' · ${e.feature}' : ''}',
      };

  String _date(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
