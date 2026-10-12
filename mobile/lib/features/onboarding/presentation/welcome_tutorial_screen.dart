import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

/// First-run, skippable guide that explains the VerifAI experience.
/// Completion is stored locally; it does not require a backend endpoint.
class WelcomeTutorialScreen extends StatefulWidget {
  const WelcomeTutorialScreen({super.key});

  @override
  State<WelcomeTutorialScreen> createState() => _WelcomeTutorialScreenState();
}

class _WelcomeTutorialScreenState extends State<WelcomeTutorialScreen> {
  static const _completionKey = 'verifai_welcome_tutorial_completed_v1';
  final PageController _pageController = PageController();
  int _page = 0;
  bool _saving = false;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      eyebrow: 'WELCOME TO VERIFAI',
      title: 'AI assists.\nHumans verify.',
      description:
          'VerifAI helps you practise the judgement needed to work with AI responsibly. You stay in charge of the final decision.',
      bullets: [
        'Learn by doing',
        'Question confident answers',
        'Keep human judgement central',
      ],
    ),
    _TutorialStep(
      eyebrow: '01 · LEARN',
      title: 'Build practical AI skills',
      description:
          'Explore workplace scenarios and short learning activities covering verification, prompt design, AI judgement, and risk and governance.',
      bullets: [
        'Explore a concept',
        'See a realistic scenario',
        'Try it for yourself',
      ],
    ),
    _TutorialStep(
      eyebrow: '02 · VERIFY',
      title: 'Look for evidence',
      description:
          'Do not accept an AI answer just because it sounds convincing. Identify claims, look for supporting evidence, and be clear when something is uncertain.',
      bullets: [
        'Check the claim',
        'Separate facts from assumptions',
        'Know when more evidence is needed',
      ],
    ),
    _TutorialStep(
      eyebrow: '03 · GET SUPPORT',
      title: 'Ask for guidance, not shortcuts',
      description:
          'The Learning Assistant can help you think through a problem and understand a concept. Your job is to question, investigate, and decide.',
      bullets: [
        'Ask for a hint',
        'Explore your reasoning',
        'Keep ownership of your answer',
      ],
    ),
    _TutorialStep(
      eyebrow: '04 · GROW',
      title: 'Learn from every attempt',
      description:
          'Complete challenges, review feedback, and follow your progress across the skills you are practising. Progress is a learning signal, not a guarantee of job readiness.',
      bullets: [
        'Complete verification tasks',
        'Review feedback',
        'Strengthen your next attempt',
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
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_completionKey, true);
    } catch (_) {
      // Navigation should remain possible if local storage is unavailable.
    }
    if (!mounted) return;
    context.go('/dashboard');
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

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  const Text(
                    'VerifAI',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Skip tutorial'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: List.generate(_steps.length, (index) {
                  final active = index <= _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 4,
                      margin: EdgeInsets.only(
                          right: index == _steps.length - 1 ? 0 : 7),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentGreen
                            : AppColors.border.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                // The controller listener keeps _page in sync; onPageChanged
                // stays as a redundant safety net for programmatic jumps.
                onPageChanged: (index) {
                  if (mounted && index != _page) {
                    setState(() => _page = index);
                  }
                },
                itemBuilder: (context, index) {
                  final item = _steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.eyebrow,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.title,
                          style:
                              AppTypography.textTheme.headlineLarge?.copyWith(
                            color: AppColors.primaryNavy,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          item.description,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ...item.bullets.map(
                          (bullet) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(top: 7),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: AppTypography.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_page > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _saving ? null : _previous,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  VerifAIButton(
                    label: _saving
                        ? 'Opening…'
                        : (isLastPage ? 'Start learning' : 'Continue'),
                    variant: isLastPage
                        ? VerifAIButtonVariant.verification
                        : VerifAIButtonVariant.primary,
                    isLoading: _saving,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<String> bullets;
}
