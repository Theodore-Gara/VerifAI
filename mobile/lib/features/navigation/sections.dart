import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The five dock areas (route, label, icon) in dock order. Mirrors
/// [MainNavShell]'s tabs so the drawer and the Home shortcut derive from one
/// list.
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
  // Help & information — shown in the hamburger menu and All Sections sheet.
  (section: 'Help & information', label: 'About Us', icon: Icons.business_rounded, route: '/about'),
  (section: 'Help & information', label: 'Help & Customer Support', icon: Icons.support_agent_rounded, route: '/support'),
  (section: 'Help & information', label: 'Frequently Asked Questions', icon: Icons.quiz_rounded, route: '/support/faq'),
  (section: 'Help & information', label: 'Contact Customer Support', icon: Icons.headset_mic_rounded, route: '/support/contact'),
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

/// Returns Home from anywhere. Used as the fallback when a pushed screen has no
/// route to pop (deep link), so Back always lands somewhere valid.
void goHome(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) navigator.popUntil((route) => route.isFirst);
  context.go('/dashboard');
}

/// Dock index hosting [route], or null when the route is not a dock area.
int? shellTabIndexFor(String route) {
  for (var i = 0; i < shellAreas.length; i++) {
    if (shellAreas[i].route == route) return i;
  }
  return null;
}
