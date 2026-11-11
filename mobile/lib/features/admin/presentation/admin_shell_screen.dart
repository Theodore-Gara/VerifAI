import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_admins_screen.dart';
import 'package:verifai/features/admin/presentation/admin_more_screen.dart';
import 'package:verifai/features/admin/presentation/admin_overview_screen.dart';
import 'package:verifai/features/admin/presentation/admin_support_screen.dart';
import 'package:verifai/features/admin/presentation/admin_users_screen.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/profile/providers.dart';

/// Dedicated native admin portal. No learner dock, drawer or learner routes are
/// reachable from here.
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // The portal renders immediately: starting the wake-up ping here means the
    // per-tab Retry buttons succeed instead of timing out again on a cold
    // backend. Fire and forget — each screen owns its own error state.
    unawaited(ref.read(apiClientProvider).ping().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(adminRoleProvider).valueOrNull;
    final canManageAdmins = role == 'admin' || role == 'super';
    final unread = ref.watch(adminUnreadTicketsProvider).valueOrNull ?? 0;

    final tabs = <_AdminTab>[
      const _AdminTab('Overview', Icons.dashboard_rounded),
      _AdminTab('Support', Icons.support_agent_rounded, badge: unread),
      const _AdminTab('Users', Icons.people_alt_rounded),
      if (canManageAdmins)
        const _AdminTab('Admins', Icons.admin_panel_settings_rounded),
      const _AdminTab('More', Icons.grid_view_rounded),
    ];
    final safeIndex = _index.clamp(0, tabs.length - 1);

    final bodies = <Widget>[
      const AdminOverviewScreen(),
      const AdminSupportScreen(),
      const AdminUsersScreen(),
      if (canManageAdmins) const AdminAdminsScreen(),
      AdminMoreScreen(role: role),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final body = IndexedStack(index: safeIndex, children: bodies);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'VerifAI Admin',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (role != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Chip(
                label: Text(role.toUpperCase()),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: AppColors.border),
              ),
            ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final tab in tabs)
                        NavigationRailDestination(
                          icon: _tabIcon(tab, false),
                          selectedIcon: _tabIcon(tab, true),
                          label: Text(tab.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final tab in tabs)
                  NavigationDestination(
                    icon: _tabIcon(tab, false),
                    selectedIcon: _tabIcon(tab, true),
                    label: tab.label,
                  ),
              ],
            ),
    );
  }

  Widget _tabIcon(_AdminTab tab, bool selected) {
    final icon = Icon(tab.icon, color: selected ? AppColors.accentGreen : null);
    if (tab.badge <= 0) return icon;
    return Badge(
      label: Text('${tab.badge}'),
      child: icon,
    );
  }
}

class _AdminTab {
  const _AdminTab(this.label, this.icon, {this.badge = 0});
  final String label;
  final IconData icon;
  final int badge;
}

/// Shared page frame for admin tool screens pushed from the More grid.
class AdminToolScaffold extends StatelessWidget {
  const AdminToolScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      body: child,
    );
  }
}
