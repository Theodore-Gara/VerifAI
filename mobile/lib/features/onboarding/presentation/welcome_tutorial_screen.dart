import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/theme/app_colors.dart';

/// First-run, skippable guide that explains the existing VerifAI experience.
/// Completion is stored locally; it does not require a backend endpoint.
class WelcomeTutorialScreen extends StatefulWidget {
  const WelcomeTutorialScreen({super.key});

  @override
  State<WelcomeTutorialScreen> createState() => _WelcomeTutorialScreenState();
}

class _WelcomeTutorialScreenState extends State<WelcomeTutorialScreen>
    with SingleTickerProviderStateMixin {
  static const _completionKey = 'verifai_welcome_tutorial_completed_v1';
  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  int _page = 0;
  bool _saving = false;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      eyebrow: 'WELCOME TO VERIFAI',
      title: 'AI assists.\nHumans verify.',
      description:
          'VerifAI helps you practise the judgement needed to work with AI responsibly. You stay in charge of the final decision.',
      icon: Icons.verified_user_rounded,
      accent: AppColors.accentGreen,
      bullets: ['Learn by doing', 'Question confident answers', 'Keep human judgement central'],
    ),
    _TutorialStep(
      eyebrow: '01 · LEARN',
      title: 'Build practical AI skills',
      description:
          'Explore workplace scenarios and short learning activities covering verification, prompt design, AI judgement, and risk and governance.',
      icon: Icons.auto_stories_rounded,
      accent: AppColors.accentCyan,
      bullets: ['Explore a concept', 'See a realistic scenario', 'Try it for yourself'],
    ),
    _TutorialStep(
      eyebrow: '02 · VERIFY',
      title: 'Look for evidence',
      description:
          'Do not accept an AI answer just because it sounds convincing. Identify claims, look for supporting evidence, and be clear when something is uncertain.',
      icon: Icons.fact_check_rounded,
      accent: Color(0xFF60A5FA),
      bullets: ['Check the claim', 'Separate facts from assumptions', 'Know when more evidence is needed'],
    ),
    _TutorialStep(
      eyebrow: '03 · GET SUPPORT',
      title: 'Ask for guidance, not shortcuts',
      description:
          'The Learning Assistant can help you think through a problem and understand a concept. Your job is to question, investigate, and decide.',
      icon: Icons.forum_rounded,
      accent: Color(0xFFA78BFA),
      bullets: ['Ask for a hint', 'Explore your reasoning', 'Keep ownership of your answer'],
    ),
    _TutorialStep(
      eyebrow: '04 · GROW',
      title: 'Learn from every attempt',
      description:
          'Complete challenges, review feedback, and follow your progress across the skills you are practising. Progress is a learning signal, not a guarantee of job readiness.',
      icon: Icons.insights_rounded,
      accent: Color(0xFFFBBF24),
      bullets: ['Complete verification tasks', 'Review feedback', 'Strengthen your next attempt'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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
    if (_page == _steps.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, AppColors.accentCyan],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AppColors.primaryNavy, size: 23),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('VerifAI', style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => _finish(),
                    child: const Text('Skip tutorial'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(_steps.length, (index) {
                  final active = index <= _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 4,
                      margin: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accentGreen : const Color(0xFFE2E8F0),
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
                onPageChanged: (index) => setState(() {
                  _page = index;
                  _animationController.forward(from: 0);
                }),
                itemBuilder: (context, index) {
                  final item = _steps[index];
                  return FadeTransition(
                    opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 206,
                                height: 206,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [item.accent.withValues(alpha: .22), item.accent.withValues(alpha: .035)]),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 142,
                                    height: 142,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(42),
                                      boxShadow: [BoxShadow(color: item.accent.withValues(alpha: .17), blurRadius: 32, offset: const Offset(0, 12))],
                                      border: Border.all(color: item.accent.withValues(alpha: .22)),
                                    ),
                                    child: Icon(item.icon, size: 70, color: AppColors.primaryNavy),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(item.eyebrow, style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.4)),
                            const SizedBox(height: 12),
                            Text(item.title, style: const TextStyle(color: AppColors.primaryNavy, fontSize: 31, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                            const SizedBox(height: 14),
                            Text(item.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6)),
                            const SizedBox(height: 22),
                            ...item.bullets.map((bullet) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(width: 23, height: 23, decoration: BoxDecoration(color: item.accent.withValues(alpha: .16), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.check_rounded, size: 16, color: AppColors.primaryNavy)),
                                const SizedBox(width: 11),
                                Expanded(child: Text(bullet, style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w700, height: 1.35))),
                              ]),
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  if (_page > 0)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _previous,
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryNavy, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
                    )
                  else
                    Text('${_page + 1} of ${_steps.length}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 176,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _next,
                      icon: Icon(_page == _steps.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 18),
                      label: Text(_saving ? 'Opening…' : (_page == _steps.length - 1 ? 'Start learning' : 'Next')),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
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
    required this.icon,
    required this.accent,
    required this.bullets,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<String> bullets;
}
