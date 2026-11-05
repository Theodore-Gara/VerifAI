import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';

/// Dismissible "Getting started" card on the dashboard.
///
/// Visible until the learner completes the tour for the current track or
/// dismisses it. "Not now" marks the tour skipped on the server so the guidance
/// stays recoverable instead of disappearing for good.
class GettingStartedCard extends ConsumerStatefulWidget {
  const GettingStartedCard({super.key, this.onDismissed});

  final VoidCallback? onDismissed;

  @override
  ConsumerState<GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends ConsumerState<GettingStartedCard> {
  bool? _dismissed;

  int? get _trackId =>
      int.tryParse(ref.read(currentUserProvider).valueOrNull?.trackId ?? '');

  String get _dismissedKey => _trackId == null
      ? 'verifai_getting_started_dismissed_v1'
      : 'verifai_getting_started_dismissed_${_trackId}_v1';

  String get _statusKey => _trackId == null
      ? 'verifai_tutorial_current_status_v1'
      : 'verifai_tutorial_${_trackId}_status_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final dismissed = preferences.getBool(_dismissedKey) ?? false;
      // Older builds stored a boolean under a separate key; treat either as
      // completion so the card does not reappear after an upgrade.
      final completed = preferences.getString(_statusKey) == 'completed' ||
          (preferences.getBool(_statusKey) ?? false);
      setState(() => _dismissed = dismissed || completed);
    } catch (_) {
      // Storage unavailable: show the card; dismissal just will not persist.
      if (mounted) setState(() => _dismissed = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_dismissedKey, true);
    } catch (_) {
      // Non-fatal: the card reappears next session instead.
    }
    try {
      await ref.read(apiClientProvider).setTourStatus(status: 'skipped');
    } catch (_) {
      // Keep the local dismissal; the next online open can sync.
    }
    ref.invalidate(tourStateProvider);
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(tourStateProvider).valueOrNull;
    final visible = _dismissed == false && (tour == null || !tour.completed);
    if (!visible) return const SizedBox.shrink();

    return Dismissible(
      key: const ValueKey('getting-started-card'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => _dismiss(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(Icons.check_rounded, color: AppColors.accentGreen),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(Icons.close_rounded, color: AppColors.textSecondary),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border:
              Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Getting started',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: _dismiss,
                ),
              ],
            ),
            _step('Confirm your industry',
                'It tailors every task to your domain.'),
            _step('Run your first task',
                'Start from the Your next task card below.'),
            _step('Track progress',
                'Skill roadmap and readiness update as you go.'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                TextButton(
                  onPressed: _dismiss,
                  child: const Text('Not now'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await context.push('/welcome-tour');
                    if (mounted) await _load();
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: const Text('Take the 60-second tour'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentGreen,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 13, color: AppColors.accentGreen),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$title — ',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: detail,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
