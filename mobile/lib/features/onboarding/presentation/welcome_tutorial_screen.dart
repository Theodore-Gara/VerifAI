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
import 'package:verifai/shared/widgets/onboarding_progress.dart';

import 'task_preview.dart';

/// Step 2 of the two-step first-run onboarding: the welcome tour.
///
/// Four pages, each answering a question the learner actually has: what is
/// this, what does a task look like, what do I get, and how do I keep going.
/// Completion is stored per track on the server, with local storage as an
/// offline cache.
class WelcomeTutorialScreen extends ConsumerStatefulWidget {
  const WelcomeTutorialScreen({super.key, this.trackId});

  final int? trackId;

  @override
  ConsumerState<WelcomeTutorialScreen> createState() =>
      _WelcomeTutorialScreenState();
}

class _WelcomeTutorialScreenState extends ConsumerState<WelcomeTutorialScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 2;
  static const int _step = 2;

  String get _completionKey {
    final trackId = widget.trackId ??
        int.tryParse(ref.read(currentUserProvider).valueOrNull?.trackId ?? '');
    return trackId == null
        ? 'verifai_tutorial_current_status_v1'
        : 'verifai_tutorial_${trackId}_status_v1';
  }

  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  int _page = 0;
  bool _saving = false;

  static final _steps = <_TutorialStep>[
    _TutorialStep(
      eyebrow: 'WHAT IS VERIFAI',
      title: 'AI assists.\nHumans verify.',
      description:
          'VerifAI helps you practise the judgement needed to work with AI responsibly. You stay in charge of the final decision.',
      icon: Icons.verified_user_rounded,
      accent: AppColors.accentGreen,
      bullets: [
        'Short scenarios drawn from your own industry',
        'You check the work, not the source code',
        'Every attempt builds a skill profile',
      ],
    ),
    const _TutorialStep(
      eyebrow: 'HOW A TASK WORKS',
      title: 'Read. Check. Decide.',
      description:
          'Every task gives you an AI output and an issue to investigate. Your job is to find what the AI got wrong, then give your verdict and reasoning.',
      icon: Icons.fact_check_rounded,
      accent: Color(0xFF3C8968),
      bullets: [
        'Read the AI scenario output',
        'Find the issue worth investigating',
        'Submit your answer and see why',
      ],
    ),
    _TutorialStep(
      eyebrow: 'WHAT YOU BUILD',
      title: 'Three skills,\nassessed as you go',
      description:
          'Every task is scored against the skills employers ask about. Your profile fills in as you practise — no separate test, no waiting.',
      icon: Icons.insights_rounded,
      accent: AppColors.xpPurple,
      bullets: const [],
      showDimensions: true,
    ),
    const _TutorialStep(
      eyebrow: 'KEEP GOING',
      title: 'Show up.\nThe progress stacks.',
      description:
          'Small, regular practice beats one long session. Streaks, XP and your skill roadmap update after every attempt you complete.',
      icon: Icons.local_fire_department_rounded,
      accent: Color(0xFFB77936),
      bullets: [
        'One task a day keeps your streak alive',
        'XP and levels track your consistency',
        'Your roadmap shows what is next',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // The page indicator is driven by the controller's real position, not by
    // onPageChanged alone. With NeverScrollableScrollPhysics the page
    // animation can settle without onPageChanged firing, which used to leave
    // the state stuck on page 1 and made Next unable to advance (bug).
    _pageController.addListener(_syncPageIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  void _syncPageIndex() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _page && mounted) {
      setState(() => _page = rounded);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncPageIndex);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _finish({bool skipped = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final status = skipped ? 'skipped' : 'completed';
    try {
      await ref.read(apiClientProvider).setTourStatus(
            status: status,
            trackId: widget.trackId,
          );
    } catch (_) {
      // Offline: the local cache below keeps the learner moving. The server
      // remains the source of truth on the next online open.
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_completionKey, status);
    } catch (_) {
      // Navigation should remain possible if local storage is unavailable.
    }
    ref.invalidate(tourStateProvider);
    if (!mounted) return;
    // A pushed tour (Profile/Help replay) returns to its caller. Onboarding
    // opens it as a root route, so fall back to Home.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  /// Skipping is a decision, not a stray tap: ask first.
  Future<void> _confirmSkip() async {
    if (_saving) return;
    final skip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip the tour?'),
        content: const Text(
          'You can take it later from your dashboard or from Profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Skip tour'),
          ),
        ],
      ),
    );
    if (skip == true) {
      await _finish(skipped: true);
    }
  }

  void _next() {
    if (_saving) return;
    if (!_pageController.hasClients) return;
    if (_page >= _steps.length - 1) {
      _finish();
      return;
    }
    // Always target the real position + 1 so repeated taps mid-animation
    // cannot wedge the pager on the same page.
    _pageController.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_saving) return;
    if (!_pageController.hasClients) return;
    if (_page <= 0) return;
    _pageController.animateToPage(
      _page - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Back from step 2 returns to step 1 so the learner can change their
  /// industry. Onboarding already completed the account, so the router would
  /// otherwise redirect straight to Home.
  void _backToIndustry() {
    if (_saving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/industry-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  const OnboardingStepBar(
                    currentStep: _step,
                    totalSteps: _totalSteps,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const OnboardingStepLabel(
                        currentStep: _step,
                        totalSteps: _totalSteps,
                      ),
                      Text(
                        'Page ${_page + 1} of ${_steps.length}',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() {
                  _page = index;
                  _animationController.forward(from: 0);
                }),
                itemBuilder: (context, index) {
                  final item = _steps[index];
                  return FadeTransition(
                    opacity: CurvedAnimation(
                        parent: _animationController, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(.04, 0), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOutCubic)),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // One visual per page: the logo opens the tour,
                            // page 2 shows the real task, and the rest carry
                            // the medallion.
                            if (index == 0)
                              Center(
                                child: Image.asset(
                                  'assets/images/logoalldarktrans.png',
                                  height: 120,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _Medallion(
                                    icon: item.icon,
                                    accent: item.accent,
                                  ),
                                ),
                              )
                            else if (index == 1)
                              const _LiveTaskPreview()
                            else
                              _Medallion(icon: item.icon, accent: item.accent),
                            const SizedBox(height: 22),
                            Text(
                              item.eyebrow,
                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  letterSpacing: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              style: AppTypography.textTheme.headlineLarge
                                  ?.copyWith(
                                      color: AppColors.primaryNavy,
                                      fontSize: 28,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.description,
                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.5,
                                  height: 1.6),
                            ),
                            const SizedBox(height: 20),
                            if (item.showDimensions)
                              const _DimensionChips(),
                            if (item.bullets.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              for (final bullet in item.bullets)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 11),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: 23,
                                          height: 23,
                                          decoration: BoxDecoration(
                                              color: item.accent
                                                  .withValues(alpha: .16),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Icon(Icons.check_rounded,
                                              size: 16,
                                              color: AppColors.primaryNavy)),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(bullet,
                                            style: AppTypography.textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color:
                                                        AppColors.primaryNavy,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.4)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _saving ? null : _backToIndustry,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Spacer(),
            Text(
              'VerifAI',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _page == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_page > 0)
                TextButton(
                  onPressed: _saving ? null : _previous,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Back'),
                ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : _confirmSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Skip tour'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _next,
              icon: Icon(
                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 18),
              label: Text(_saving
                  ? 'Saving…'
                  : (isLast ? 'Start learning' : 'Next')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryFill,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular icon plate behind each page's headline.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const outer = 180.0;
    const inner = 124.0;
    return Center(
      child: Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            accent.withValues(alpha: .22),
            accent.withValues(alpha: .035)
          ]),
        ),
        child: Center(
          child: Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(inner * .3),
              boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: .17),
                    blurRadius: 32,
                    offset: const Offset(0, 12))
              ],
              border: Border.all(color: accent.withValues(alpha: .22)),
            ),
            child: Icon(icon, size: 62, color: AppColors.primaryNavy),
          ),
        ),
      ),
    );
  }
}

/// The three skills the app assesses. Real names, so the learner recognises
/// them later on their profile.
class _DimensionChips extends StatelessWidget {
  const _DimensionChips();

  @override
  Widget build(BuildContext context) {
    const dimensions = [
      (Icons.fact_check_rounded, 'Verification',
          'Check an AI output for errors'),
      (Icons.psychology_rounded, 'AI Judgement',
          'Decide what to do with an answer'),
      (Icons.shield_outlined, 'Risk & Governance',
          'Spot the risk before it lands'),
    ];
    return Column(
      children: [
        for (final (icon, title, detail) in dimensions) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryNavy),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Shows the learner's real next task so the tour shows the product rather
/// than describing it. Falls back to a static example when no task is
/// available yet.
class _LiveTaskPreview extends ConsumerWidget {
  const _LiveTaskPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(tourPreviewTaskProvider);
    return taskAsync.maybeWhen(
      data: (task) {
        if (task == null) return const TaskPreviewPlaceholder();
        return TaskPreview(
          task: task,
          selectedOptionId:
              task.options.isNotEmpty ? task.options.first.id : null,
        );
      },
      orElse: () => const TaskPreviewPlaceholder(),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.bullets = const [],
    this.showDimensions = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<String> bullets;

  /// Show the three assessed skills instead of the bullet list.
  final bool showDimensions;
}
