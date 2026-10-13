import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/shared/models.dart';

/// Reward product page: what it is, how it is earned and redeemed.
class RewardDetailScreen extends ConsumerStatefulWidget {
  const RewardDetailScreen({super.key, required this.reward});
  final Reward reward;

  @override
  ConsumerState<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends ConsumerState<RewardDetailScreen> {
  bool _redeeming = false;
  int? _remainingTokens;

  Future<void> _redeem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Redeem ${widget.reward.title}?'),
        content: Text('This spends ${widget.reward.costTokens} reward tokens from your balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Redeem')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _redeeming = true);
    try {
      final result = await ref.read(apiClientProvider).redeemReward(widget.reward.code);
      if (!mounted) return;
      setState(() => _remainingTokens = result.wallet.tokens);
      ref.invalidate(rewardsProvider);
      ref.invalidate(dashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Redeemed "${widget.reward.title}". You have ${result.wallet.tokens} tokens left.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not redeem — check your token balance.')));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final tokens = _remainingTokens;
    final canRedeem = tokens == null ? r.canAfford : tokens >= r.costTokens;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Reward',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
            AppSpacing.screenPadding, AppSpacing.xxl),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accentGreen.withValues(alpha: .2),
                AppColors.accentCyan.withValues(alpha: .2),
              ]),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Center(child: Icon(Icons.card_giftcard_rounded, size: 60, color: AppColors.primaryNavy)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(r.title,
              style: AppTypography.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
          const SizedBox(height: 4),
          Text(r.subtitle, style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          _row('Cost', '${r.costTokens} tokens'),
          if (tokens != null) _row('Your balance', '$tokens tokens'),
          if (r.note != null) _row('Note', r.note!),
          const SizedBox(height: AppSpacing.lg),
          _info(
            'How you earn tokens',
            'Reward tokens are earned as you progress — you gain tokens for every level you reach and '
                'for achievements you unlock. XP keeps rising as a permanent record; tokens are the '
                'spendable currency.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _info(
            'How redemption works',
            'Redeeming a reward deducts its cost from your token balance. Your XP and level are never '
                'affected. Fulfilment depends on a verified partner for physical or voucher rewards.',
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _redeeming || !canRedeem ? null : _redeem,
            icon: _redeeming
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.redeem_rounded),
            label: Text(_redeeming ? 'Redeeming…' : (canRedeem ? 'Redeem reward' : 'Not enough tokens yet')),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
            Text(value,
                style: AppTypography.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
          ],
        ),
      );

  Widget _info(String title, String body) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTypography.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
            const SizedBox(height: 4),
            Text(body, style: AppTypography.textTheme.bodySmall?.copyWith(height: 1.45)),
          ],
        ),
      );
}
