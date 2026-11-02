import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';

/// The five dock areas (route, label, icon) in dock order. Mirrors
/// [MainNavShell]'s tabs so the drawer, the all-sections sheet and the Home
/// shortcut all derive from one list.
const shellAreas = <({String label, IconData icon, String route})>[
  (label: 'Home', icon: Icons.home_rounded, route: '/dashboard'),
  (label: 'Learn', icon: Icons.menu_book_rounded, route: '/learn'),
  (label: 'Practice', icon: Icons.play_circle_outline_rounded, route: '/practice'),
  (label: 'Progress', icon: Icons.insights_rounded, route: '/progress'),
  (label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
];

/// Every destination in the app, grouped under its dock area. Single source of
/// truth for the drawer and the all-sections sheet.
const allSections = <({String section, String label, IconData icon, String route})>[
  // Home
  (section: 'Home', label: 'Dashboard', icon: Icons.home_rounded, route: '/dashboard'),
  // Learn
  (section: 'Learn', label: 'Learn hub', icon: Icons.menu_book_rounded, route: '/learn'),
  (section: 'Learn', label: 'AI Lab lessons', icon: Icons.science_rounded, route: '/ai-lab/lessons'),
  (section: 'Learn', label: 'Recall practice', icon: Icons.quiz_rounded, route: '/ai-lab/practice'),
  (section: 'Learn', label: 'Capstone assessments', icon: Icons.workspace_premium_rounded, route: '/ai-lab/assessments'),
  (section: 'Learn', label: 'Skill roadmap', icon: Icons.alt_route_rounded, route: '/track'),
  // Practice
  (section: 'Practice', label: 'Practice hub', icon: Icons.play_circle_outline_rounded, route: '/practice'),
  (section: 'Practice', label: 'Verification Studio', icon: Icons.fact_check_rounded, route: '/verification-studio'),
  (section: 'Practice', label: 'Industry practice', icon: Icons.business_center_rounded, route: '/industry-practice'),
  (section: 'Practice', label: 'Task history', icon: Icons.history_rounded, route: '/task-history'),
  // Progress
  (section: 'Progress', label: 'Progress', icon: Icons.insights_rounded, route: '/progress'),
  (section: 'Progress', label: 'Leaderboard', icon: Icons.leaderboard_rounded, route: '/scoreboard'),
  // Profile
  (section: 'Profile', label: 'Profile & settings', icon: Icons.person_rounded, route: '/profile'),
  (section: 'Profile', label: 'Rewards', icon: Icons.emoji_events_rounded, route: '/rewards'),
  (section: 'Profile', label: 'Wellness centre', icon: Icons.spa_rounded, route: '/wellness'),
  (section: 'Profile', label: 'Ask Vera', icon: Icons.auto_awesome_rounded, route: '/assistant'),
  (section: 'Profile', label: 'Change industry', icon: Icons.swap_horiz_rounded, route: '/change-industry'),
  // Help & information
  (section: 'Help & information', label: 'Help & Customer Support', icon: Icons.support_agent_rounded, route: '/support'),
  (section: 'Help & information', label: 'Frequently Asked Questions', icon: Icons.quiz_rounded, route: '/support/faq'),
  (section: 'Help & information', label: 'Contact Us', icon: Icons.mail_outline_rounded, route: '/support/contact'),
  (section: 'Help & information', label: 'About VerifAI', icon: Icons.info_outline_rounded, route: '/about'),
];

/// Shell routes that must switch the dock in place rather than `go`/`push`
/// (a second shell would collide on the shared scaffold global key). Mirrors
/// MainNavShell.shellTabRoutes.
const shellTabRoutes = <String>{
  '/dashboard',
  '/learn',
  '/practice',
  '/progress',
  '/profile',
};

/// Returns Home from anywhere. From a pushed screen it is one tap: the Home
/// action in the secondary app bar. Pops pushed routes back to the shell first
/// so Back semantics stay honest, then lands on the dashboard.
void goHome(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) navigator.popUntil((route) => route.isFirst);
  context.go('/dashboard');
}

/// Opens the All sections bottom sheet — the complete destination index that
/// pushed screens use in place of the shell's drawer.
Future<void> showAllSectionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
    ),
    builder: (sheetContext) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          children: [
            Text(
              'All sections',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Everything in VerifAI, from anywhere.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < allSections.length; i++) ...[
              if (i == 0 || allSections[i].section != allSections[i - 1].section)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(
                    allSections[i].section.toUpperCase(),
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(allSections[i].icon,
                    color: AppColors.accentGreen, size: 20),
                title: Text(allSections[i].label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  final route = allSections[i].route;
                  Navigator.pop(sheetContext);
                  if (shellTabRoutes.contains(route)) {
                    // Dock areas: pop any pushed screens, then switch the dock
                    // in place — `go` to a sibling shell route mounts a second
                    // shell and collides on the shared scaffold key.
                    final navigator = Navigator.of(sheetContext);
                    if (navigator.canPop()) {
                      navigator.popUntil((r) => r.isFirst);
                    }
                    final index = shellTabIndexFor(route);
                    if (index != null) switchShellTab(index);
                  } else {
                    context.push(route);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Dock index hosting [route], or null when the route is not a dock area.
int? shellTabIndexFor(String route) {
  for (var i = 0; i < shellAreas.length; i++) {
    if (shellAreas[i].route == route) return i;
  }
  return null;
}