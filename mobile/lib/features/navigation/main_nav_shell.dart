import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:verifai/features/hubs/presentation/learn_hub_screen.dart';
import 'package:verifai/features/hubs/presentation/practice_hub_screen.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/features/profile/presentation/profile_screen.dart';
import 'package:verifai/features/progress/presentation/progress_screen.dart';

/// Routes hosted by [MainNavShell]. These must stay `go` (never `push`) —
/// stacking a second shell would duplicate [verifaiMainScaffoldKey].
const shellTabRoutes = {
  '/dashboard',
  '/learn',
  '/practice',
  '/progress',
  '/profile',
};

/// Dock index of each shell-tab route, in [_navTabs] order. Lets any in-app link
/// switch tabs in place instead of `go`-ing to a sibling shell route.
const shellTabIndex = <String, int>{
  '/dashboard': 0,
  '/learn': 1,
  '/practice': 2,
  '/progress': 3,
  '/profile': 4,
};

/// Five top-level areas, with each area's destinations gathered in a hub.
///
/// The previous layout had three overlapping navigation systems: a 13-link
/// drawer, a five-item dock whose tabs were Home/Track/Tasks/Progress/Profile,
/// and separate full-screen routes for things like rewards and history. A
/// learner could reach the same screen three ways and could not tell which one
/// was canonical. Now the dock is the only top-level navigation and every hub
/// owns the screens that belong to it.
const _navTabs = <_NavTab>[
  _NavTab(label: 'Home', icon: Icons.home_rounded),
  _NavTab(label: 'Learn', icon: Icons.menu_book_rounded),
  _NavTab(label: 'Practice', icon: Icons.play_circle_outline_rounded),
  _NavTab(label: 'Progress', icon: Icons.insights_rounded),
  _NavTab(label: 'Profile', icon: Icons.person_rounded),
];

class _NavTab {
  final String label;
  final IconData icon;
  const _NavTab({required this.label, required this.icon});
}

class MainNavShell extends StatefulWidget {
  final int initialIndex;

  const MainNavShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  late int _currentIndex;

  // Tabs are built on first visit. An IndexedStack builds every child, so the
  // old eager list resolved the providers of all five tabs on cold start (~10
  // requests before the learner tapped anything).
  static final List<Widget Function()> _tabBuilders = <Widget Function()>[
    () => const DashboardScreen(),
    () => const LearnHubScreen(),
    () => const PracticeHubScreen(),
    () => const ProgressScreen(),
    () => const ProfileScreen(),
  ];

  final List<Widget?> _tabs = List<Widget?>.filled(_tabBuilders.length, null);

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, _tabBuilders.length - 1).toInt();
    _tabs[_currentIndex] = _tabBuilders[_currentIndex]();
    registerShellTabSwitcher(_onItemTapped);
  }

  @override
  void dispose() {
    unregisterShellTabSwitcher();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tabs[index] ??= _tabBuilders[index]();
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: verifaiMainScaffoldKey,
      extendBody: true,
      // Secondary navigation: the dock is primary, the drawer is the complete
      // index of destinations. Hub routes are shell tabs (`go`) and everything
      // else is pushed, so Back always returns to the hub it was opened from.
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryFill, AppColors.greenFill],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/wordmarkwhite.png',
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'AI assists. Humans verify.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _drawerSection('Home'),
              _drawerLink(
                  context, Icons.home_rounded, 'Dashboard', '/dashboard'),
              _drawerSection('Learn'),
              _drawerLink(
                  context, Icons.menu_book_rounded, 'Learn hub', '/learn'),
              _drawerLink(context, Icons.science_rounded, 'AI Lab lessons',
                  '/ai-lab/lessons'),
              _drawerLink(context, Icons.quiz_rounded, 'Recall practice',
                  '/ai-lab/practice'),
              _drawerLink(context, Icons.workspace_premium_rounded,
                  'Capstone assessments', '/ai-lab/assessments'),
              _drawerLink(
                  context, Icons.alt_route_rounded, 'Skill roadmap', '/track'),
              _drawerSection('Practice'),
              _drawerLink(context, Icons.play_circle_outline_rounded,
                  'Practice hub', '/practice'),
              _drawerLink(context, Icons.fact_check_rounded,
                  'Verification Studio', '/verification-studio'),
              _drawerLink(context, Icons.business_center_rounded,
                  'Industry practice', '/industry-practice'),
              _drawerLink(context, Icons.history_rounded, 'Task history',
                  '/task-history'),
              _drawerSection('Progress'),
              _drawerLink(
                  context, Icons.insights_rounded, 'Progress', '/progress'),
              _drawerLink(context, Icons.leaderboard_rounded, 'Leaderboard',
                  '/scoreboard'),
              _drawerSection('Profile'),
              _drawerLink(context, Icons.person_rounded, 'Profile & settings',
                  '/profile'),
              _drawerLink(
                  context, Icons.emoji_events_rounded, 'Rewards', '/rewards'),
              _drawerLink(
                  context, Icons.spa_rounded, 'Wellness centre', '/wellness'),
              _drawerLink(context, Icons.auto_awesome_rounded, 'Ask Vera',
                  '/assistant'),
              const Divider(indent: 18, endIndent: 18),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Text(
                  'AI assists. Humans verify.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _tabs[i] ?? const SizedBox.shrink(),
        ],
      ),
      // Scrollable tabs end their content above the floating dock rather than
      // guessing a number: the dock's height plus the device's bottom inset, so
      // the last card is never hidden behind it (and never over-padded).
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 8 : 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var index = 0; index < _navTabs.length; index++)
                      _buildNavItem(
                        index: index,
                        icon: _navTabs[index].icon,
                        label: _navTabs[index].label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _drawerLink(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.accentGreen, size: 20),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () {
        Navigator.of(context).pop();
        final tab = shellTabIndex[route];
        if (tab != null) {
          // Switch the dock in place; `go` to a sibling shell route collides on
          // the shared scaffold global key.
          _onItemTapped(tab);
        } else {
          context.push(route);
        }
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    // 48dp minimum target: the old item was icon(20) + 8dp padding ≈ 36dp, and
    // a bare GestureDetector gave no ripple, focus or accessibility action.
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$label, selected' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => _onItemTapped(index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              // easeOutCubic, not an overshooting curve: a partly-negated
              // shadow lerp trips Flutter's `blurRadius >= 0` assertion when the
              // selection animates.
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryFill : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryFill.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
