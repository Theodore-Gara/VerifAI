import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/providers/track_scope.dart';
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

/// Step 1 of the two-step first-run onboarding: pick an industry.
///
/// Step 2 is the welcome tour. Both screens share the same hero treatment and
/// step indicator so the journey reads as one flow.
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

  /// The track the learner has picked, resolved from the catalogue so the
  /// confirm button can name it.
  IndustryTrack? get _selectedTrack {
    final id = _selectedTrackId;
    if (id == null) return null;
    final tracks = ref.read(tracksProvider).valueOrNull ?? const [];
    for (final track in tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final currentTrackId = int.tryParse(user?.trackId ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.isChangingIndustry,
        titleSpacing: AppSpacing.screenPadding,
        title: Text(
          widget.isChangingIndustry ? 'Change Industry' : 'Set up your path',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        leading: widget.isChangingIndustry
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _cancel,
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
            : _buildTracksList(tracks, currentTrackId),
        loading: () => _buildShimmerList(),
        error: (error, stackTrace) => AsyncErrorView(
          error: error,
          fallbackMessage: 'Failed to load industry tracks. Please try again.',
          onRetry: () => reconnectApp(ref),
        ),
      ),
      bottomNavigationBar: _selectedTrackId != null
          ? _buildBottomBar()
          : null,
    );
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _handleContinue() async {
    final trackId = _selectedTrackId;
    if (trackId == null || _isSubmitting) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    final currentTrackId = int.tryParse(user?.trackId ?? '');
    if (currentTrackId == trackId) return;

    final tracks = ref.read(tracksProvider).valueOrNull ?? const [];
    IndustryTrack? target;
    for (final track in tracks) {
      if (track.id == trackId) {
        target = track;
        break;
      }
    }
    if (target == null) return;

    if (widget.isChangingIndustry) {
      final hasProgress = await _loadHasProgress();
      if (!mounted) return;
      if (hasProgress) {
        final confirmed = await _confirmSwitch(
          user?.trackName ?? 'Your current industry',
          target.name,
        );
        if (confirmed != true || !mounted) return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // Call the repository directly: selectTrackProvider is a cached
      // FutureProvider.family, so after one failure a retry would re-throw the
      // same cached error without ever reaching the network.
      final result =
          await ref.read(trackRepositoryProvider).selectTrack(trackId);
      ref.read(selectedTrackProvider.notifier).state = trackId;
      // The old track's tasks, lessons, leaderboard and readiness are now
      // stale: invalidate every track-scoped provider in one place so no
      // screen keeps rendering the previous industry.
      invalidateTrackScopedProviders(ref);
      if (!widget.isChangingIndustry) {
        await ref.read(authNotifierProvider.notifier).completeOnboarding();
      }

      if (!mounted) return;
      if (!widget.isChangingIndustry) {
        context.go('/welcome-tour', extra: trackId);
        return;
      }

      // New track: offer its introduction once, without blocking Home.
      final targetName =
          result.trackName.isEmpty ? target.name : result.trackName;
      if (result.tour?.shouldOffer == true && await _offerTour(targetName)) {
        if (!mounted) return;
        context.go('/welcome-tour', extra: trackId);
        return;
      }
      if (!mounted) return;
      context.go('/dashboard');
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

  Future<bool> _loadHasProgress() async {
    try {
      final data = await ref.read(dashboardProvider.future);
      return data.completedTasks > 0 || data.overallScore > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool?> _confirmSwitch(String currentName, String targetName) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch industry?'),
        content: Text(
          'Your $currentName progress is saved. $targetName starts at Novice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  Future<bool> _offerTour(String targetName) async {
    final take = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('New to $targetName?'),
        content: const Text('Take the 60-second introduction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Take the tour'),
          ),
        ],
      ),
    );
    return take == true;
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    final track = _selectedTrack;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
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
                label: track == null
                    ? 'Continue'
                    : 'Continue with ${track.name}',
                variant: VerifAIButtonVariant.verification,
                isLoading: _isSubmitting,
                onPressed: _handleContinue,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksList(List<IndustryTrack> tracks, int? currentTrackId) {
    final selected = _selectedTrack;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        if (widget.isChangingIndustry) ...[
          _SwitchNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        OnboardingHero(
          eyebrow: widget.isChangingIndustry
              ? 'CHANGE YOUR PATH'
              : 'STEP 1 OF 2',
          title: widget.isChangingIndustry
              ? 'Pick a new industry'
              : 'What do you work in?',
          subtitle: widget.isChangingIndustry
              ? 'Your XP, level, streak and tokens stay with you. Tasks, lessons and the tutorial switch to the new industry.'
              : 'We tailor every daily challenge, lesson and skill tree to your domain. You can change this later at any time.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Choose your industry',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tap one to select it.',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final track in tracks) ...[
          _TrackRow(
            track: track,
            isSelected: _selectedTrackId == track.id,
            isCurrent: currentTrackId == track.id,
            onTap: () {
              if (_isSubmitting || currentTrackId == track.id) return;
              HapticFeedback.selectionClick();
              setState(() {
                _selectedTrackId = track.id;
                _submitError = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xs),
        if (selected != null) ...[
          _GuideHint(
            track: selected,
            onTap: () => context.push(
              '/industry-guide/${Uri.encodeComponent(selected.name)}',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShimmerList() {
    // Scrollable, like the real list: the placeholder for a phone-sized
    // screen is taller than a short viewport.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        ShimmerLoader(
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(AppRadius.hero)),
        const SizedBox(height: AppSpacing.lg),
        ShimmerLoader(
            width: double.infinity,
            height: 28,
            borderRadius: BorderRadius.circular(AppRadius.md)),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < 4; i++) ...[
          ShimmerLoader(
              width: double.infinity,
              height: 92,
              borderRadius: BorderRadius.circular(AppRadius.card)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Explains what a switch does and does not carry over. Shown only when the
/// learner is changing an existing industry.
class _SwitchNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:
            Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What switching means',
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kept — your XP, level, streak and tokens stay as they '
            'are, and your previous progress is saved.\n'
            'Changes — tasks, lessons, readiness and the tutorial '
            'switch to the new industry. You can switch back at any '
            'time.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One industry in the list.
///
/// A single column rather than a grid: the catalogue grows as tracks are
/// added, and a list gives each one room for its description.
class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  final IndustryTrack track;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final perk = track.perk ?? '★ Readiness Path';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${track.name}. ${track.description ?? ''}'.trim(),
      excludeSemantics: true,
      child: Material(
        color: isSelected
            ? AppColors.accentLight.withValues(alpha: 0.55)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    // primaryFill stays deep in both themes, so the selected
                    // tile keeps its contrast in dark mode. primaryNavy
                    // inverts to near-white there and would wash out.
                    color: isSelected
                        ? AppColors.primaryFill
                        : AppColors.accentLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    _iconFor(track),
                    size: 24,
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              track.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _Pill(label: 'CURRENT'),
                          ],
                        ],
                      ),
                      if ((track.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          track.description!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SelectionBadge(isSelected: isSelected, isCurrent: isCurrent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "CURRENT" tag for the industry the learner is already on.
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.w900,
          fontSize: 9.5,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Trailing check / chevron. The current industry is not selectable, so it
/// gets a neutral marker instead of a chevron that promises navigation.
class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.isSelected, required this.isCurrent});

  final bool isSelected;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }
    return Icon(
      isCurrent
          ? Icons.check_circle_outline_rounded
          : Icons.chevron_right_rounded,
      color: isCurrent ? AppColors.accentGreen : AppColors.textSecondary,
      size: 20,
    );
  }
}

/// "See how X works" row that opens the industry guide. Only rendered once an
/// industry is picked — with nothing selected it was a dead end. Lives outside
/// the cards so a card tap only ever selects.
class _GuideHint extends StatelessWidget {
  const _GuideHint({required this.track, required this.onTap});

  final IndustryTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Icon(
            Icons.menu_book_rounded,
            color: AppColors.accentGreen,
            size: 22,
          ),
          title: Text(
            'See how ${track.name} works',
            style: AppTypography.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'A short guide to what you will practise',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

/// Maps a track to its glyph.
///
/// The catalogue supplies `icon_key` so a track added on the server renders
/// correctly without a client release. The name-based fallback covers tracks
/// that have no icon_key yet.
IconData _iconFor(IndustryTrack track) {
  final key = (track.iconKey ?? '').toLowerCase();
  switch (key) {
    case 'finance':
      return Icons.account_balance_rounded;
    case 'legal':
      return Icons.gavel_rounded;
    case 'it':
    case 'software':
      return Icons.code_rounded;
    case 'consulting':
    case 'business':
      return Icons.business_center_rounded;
    case 'health':
    case 'healthcare':
      return Icons.local_hospital_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'manufacturing':
      return Icons.precision_manufacturing_rounded;
    case 'retail':
    case 'ecommerce':
      return Icons.storefront_rounded;
    case 'public':
    case 'government':
      return Icons.account_balance_outlined;
  }
  // No icon_key: fall back to matching on the name so the four seeded tracks
  // still get their glyph if the column has not been backfilled yet.
  switch (track.name.toLowerCase()) {
    case 'finance':
      return Icons.account_balance_rounded;
    case 'legal':
      return Icons.gavel_rounded;
    case 'it / software':
      return Icons.code_rounded;
    case 'business consulting':
      return Icons.business_center_rounded;
  }
  return Icons.work_rounded;
}
