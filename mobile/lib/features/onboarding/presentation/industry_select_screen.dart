import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets.dart';

class IndustrySelectScreen extends ConsumerStatefulWidget {
  const IndustrySelectScreen({
    super.key,
    this.isChangingIndustry = false,
  });

  final bool isChangingIndustry;

  @override
  ConsumerState<IndustrySelectScreen> createState() =>
      _IndustrySelectScreenState();
}

class _IndustrySelectScreenState extends ConsumerState<IndustrySelectScreen> {
  int? _selectedTrackId;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isChangingIndustry
              ? 'Change Industry'
              : 'Choose Specialization',
        ),
        automaticallyImplyLeading: widget.isChangingIndustry,
        leading: widget.isChangingIndustry
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/profile'),
              )
            : null,
      ),
      body: tracksAsync.when(
        data: (tracks) => tracks.isEmpty
            ? EmptyState(
                icon: Icons.work_off_outlined,
                title: 'No industries available yet',
                message:
                    'We could not find any industry tracks to choose from. Please check back shortly.',
                actionLabel: 'Refresh',
                onAction: () => ref.invalidate(tracksProvider),
              )
            : _buildTracksList(tracks),
        loading: () => _buildShimmerList(),
        error: (error, stackTrace) => AsyncErrorView(
          error: error,
          fallbackMessage: 'Failed to load industry tracks. Please try again.',
          onRetry: () => reconnectApp(ref),
        ),
      ),
      bottomNavigationBar: _selectedTrackId != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_submitError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _submitError!,
                                style: AppTypography.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    VerifAIButton(
                      label: _submitError != null ? 'Try Again' : 'Continue',
                      variant: VerifAIButtonVariant.verification,
                      isLoading: _isSubmitting,
                      onPressed: _handleContinue,
                      leadingIcon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _handleContinue() async {
    final trackId = _selectedTrackId;
    if (trackId == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // Call the repository directly: selectTrackProvider is a cached
      // FutureProvider.family, so after one failure a retry would re-throw the
      // same cached error without ever reaching the network.
      await ref.read(trackRepositoryProvider).selectTrack(trackId);
      ref.read(selectedTrackProvider.notifier).state = trackId;
      ref.invalidate(dashboardProvider);
      if (!widget.isChangingIndustry) {
        await ref.read(authNotifierProvider.notifier).completeOnboarding();
      }

      if (!mounted) return;
      context.go(widget.isChangingIndustry ? '/dashboard' : '/welcome-tour');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError =
            'We could not save your industry. ${classifyError(e).message}';
      });
      showFeedback(
        context,
        FeedbackKind.error,
        _submitError!,
      );
    }
  }

  Widget _buildTracksList(List<IndustryTrack> tracks) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Industry',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We tailor your daily AI verification challenges and skill tree roadmap to your domain.',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'STEP 1 OF 1',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 240,
              ),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isSelected = _selectedTrackId == track.id;
                return _TrackCard(
                  track: track,
                  isSelected: isSelected,
                  onTap: () {
                    if (_isSubmitting) return;
                    setState(() {
                      _selectedTrackId = track.id;
                      _submitError = null;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          ShimmerLoader(
              width: double.infinity,
              height: 28,
              borderRadius: BorderRadius.circular(AppRadius.md)),
          const SizedBox(height: AppSpacing.sm),
          ShimmerLoader(
              width: double.infinity,
              height: 18,
              borderRadius: BorderRadius.circular(AppRadius.md)),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 240,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ShimmerLoader.card(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final IndustryTrack track;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrackCard({
    required this.track,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final perk = _getTrackPerk(track.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentLight.withValues(alpha: 0.55)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryNavy
                      : AppColors.primaryNavy.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTrackIcon(track.name),
                  size: 24,
                  color: isSelected
                      ? AppColors.accentGreen
                      : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                track.name,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                track.description ?? '',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                perk,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTrackPerk(String name) {
    switch (name.toLowerCase()) {
      case 'finance':
        return '★ Numerical Auditing';
      case 'legal':
        return '★ Clause Citation';
      case 'it / software':
        return '★ Code Verification';
      case 'business consulting':
        return '★ Strategy Governance';
      default:
        return '★ Readiness Path';
    }
  }

  IconData _getTrackIcon(String name) {
    switch (name.toLowerCase()) {
      case 'finance':
        return Icons.account_balance_rounded;
      case 'legal':
        return Icons.gavel_rounded;
      case 'it / software':
        return Icons.code_rounded;
      case 'business consulting':
        return Icons.business_center_rounded;
      default:
        return Icons.work_rounded;
    }
  }
}
