import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/features/progress/presentation/progress_screen.dart';
import 'package:verifai/features/task/presentation/task_screen.dart';
import 'package:verifai/features/track/presentation/track_roadmap_screen.dart';
import 'package:verifai/features/profile/presentation/profile_screen.dart';

/// Routes hosted by [MainNavShell]. These must stay `go` (never `push`) —
/// stacking a second shell would duplicate [verifaiMainScaffoldKey].
const shellTabRoutes = {'/dashboard', '/track', '/tasks', '/progress', '/profile'};

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

  final List<Widget> _screens = const [
    DashboardScreen(),
    TrackRoadmapScreen(),
    TaskScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: verifaiMainScaffoldKey,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryNavy, AppColors.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              _drawerLink(context, Icons.home_rounded, 'Home', '/dashboard'),
              _drawerLink(
                  context, Icons.route_rounded, 'Skill roadmap', '/track'),
              _drawerLink(context, Icons.task_alt_rounded, 'Tasks', '/tasks'),
              _drawerLink(context, Icons.verified_rounded,
                  'Verification Studio', '/verification-studio'),
              _drawerLink(context, Icons.auto_awesome_rounded, 'Ask Vera',
                  '/assistant'),
              _drawerLink(context, Icons.science_rounded, 'AI Lab', '/ai-lab'),
              _drawerLink(context, Icons.fitness_center_rounded, 'Practice',
                  '/industry-practice'),
              _drawerLink(
                  context, Icons.insights_rounded, 'Progress', '/progress'),
              _drawerLink(context, Icons.leaderboard_rounded, 'Leaderboard',
                  '/scoreboard'),
              _drawerLink(
                  context, Icons.emoji_events_rounded, 'Rewards', '/rewards'),
              _drawerLink(context, Icons.history_rounded, 'Task history',
                  '/task-history'),
              _drawerLink(
                  context, Icons.spa_rounded, 'Wellness Centre', '/wellness'),
              _drawerLink(context, Icons.person_rounded, 'Profile & settings',
                  '/profile'),
              const Divider(indent: 18, endIndent: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Text(
                  'AI assists. Humans verify.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.alt_route_rounded,
                      label: 'Track',
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.insights_rounded,
                      label: 'Progress',
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.person_rounded,
                      label: 'Profile',
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

  Widget _drawerLink(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentGreen),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () {
        Navigator.of(context).pop();
        // Everything that isn't a shell tab is pushed, so the route it came
        // from stays on the stack and Back returns to it.
        if (shellTabRoutes.contains(route)) {
          context.go(route);
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

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
