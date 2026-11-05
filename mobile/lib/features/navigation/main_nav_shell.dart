import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:verifai/features/hubs/presentation/learn_hub_screen.dart';
import 'package:verifai/features/hubs/presentation/practice_hub_screen.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/features/navigation/sections.dart';
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

class MainNavShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends ConsumerState<MainNavShell> {
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
    final trackName = ref.watch(currentUserProvider).valueOrNull?.trackName;

    return Scaffold(
      key: verifaiMainScaffoldKey,
      extendBody: true,
      // Secondary navigation: the dock is primary, the drawer is the complete
      // index of destinations. Hub routes are shell tabs (`go`) and everything
      // else is pushed, so Back always returns to the hub it was opened from.
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Column(
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
                    if (trackName != null && trackName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/change-industry');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  trackName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_rounded,
                                  size: 13, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                // The complete destination index, generated from the shared
                // allSections list so the drawer and the all-sections sheet
                // can never drift apart.
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < allSections.length; i++) ...[
                      if (i == 0 ||
                          allSections[i].section != allSections[i - 1].section)
                        _drawerSection(allSections[i].section),
                      _drawerLink(context, allSections[i].icon,
                          allSections[i].label, allSections[i].route),
                    ],
                  ],
                ),
              ),
              // Account footer: log out lives here on every screen, with a
              // confirm dialog so a stray tap cannot sign the learner out.
              const Divider(indent: 18, endIndent: 18, height: 1),
              _drawerLogout(context),
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

  Widget _drawerLogout(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
      title: Text('Log out',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.error)),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer first
        _confirmLogout(context);
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text('Log out?',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        content: const Text(
            'You will need to sign in again to continue where you left off.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performLogout(context);
            },
            child: Text('Log out',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Sign-out clears auth state; the router redirect lands on /login and the
    // auth listener in app_router.dart invalidates every user-scoped cache,
    // so no signed-out screen ever shows the previous user's data.
    await ref.read(authNotifierProvider.notifier).logout();
    messenger.showSnackBar(
      const SnackBar(content: Text('You are signed out.')),
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
