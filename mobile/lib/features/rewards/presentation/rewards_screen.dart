import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/rewards/presentation/reward_detail_screen.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Rewards — token wallet + catalogue.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rewardsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Rewards',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [ShimmerLoader(height: 110), SizedBox(height: AppSpacing.md), ShimmerLoader(height: 90), SizedBox(height: AppSpacing.sm), ShimmerLoader(height: 90)],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load rewards.',
          onRetry: () => ref.invalidate(rewardsProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
              AppSpacing.screenPadding, AppSpacing.xxl),
          children: [
            _wallet(context, data.wallet),
            const SizedBox(height: AppSpacing.lg),
            Text('Spend your tokens',
                style: AppTypography.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
            const SizedBox(height: AppSpacing.sm),
            if (data.rewards.isEmpty)
              const EmptyState(icon: Icons.card_giftcard_outlined, title: 'No rewards yet', message: '')
            else
              for (final r in data.rewards) _card(context, ref, r),
          ],
        ),
      ),
    );
  }

  Widget _wallet(BuildContext context, RewardWallet w) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryNavy, Color(0xFF176B68)]),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('REWARD TOKENS',
                      style: TextStyle(
                          color: AppColors.accentCyan, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                  Text('${w.tokens}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  Text('Level ${w.level} · ${w.xp} XP',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.workspace_premium_rounded, color: Colors.white24, size: 54),
          ],
        ),
      );

  Widget _card(BuildContext context, WidgetRef ref, Reward r) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RewardDetailScreen(reward: r)));
              ref.invalidate(rewardsProvider);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: r.canAfford ? AppColors.accentGreen.withValues(alpha: .5) : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: AppTypography.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                        Text(r.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('${r.costTokens}',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: r.canAfford ? AppColors.accentGreen : AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      );
}
