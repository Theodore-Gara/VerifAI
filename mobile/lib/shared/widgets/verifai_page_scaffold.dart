import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/navigation/sections.dart';

/// Shared scaffold for every screen pushed on top of [MainNavShell].
///
/// Guarantees the navigation contract:
///  - Back is always the first action (the system back gesture works too; the
///    visible button just makes it discoverable).
///  - Home is one tap away (`goHome`) — any screen is at most two taps from
///    Home counting the dock's Home tab.
///  - The full destination index ("All sections") opens as a bottom sheet,
///    because pushed screens sit above the shell and cannot open its drawer.
///
/// Hub/dock screens (dashboard, hubs, progress, profile) keep their own
/// scaffolds — they already host the dock and drawer.
class VerifaiPageScaffold extends StatelessWidget {
  const VerifaiPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              goHome(context);
            }
          },
        ),
        title: Text(
          title,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goHome(context),
          ),
          IconButton(
            tooltip: 'All sections',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => showAllSectionsSheet(context),
          ),
          ...actions,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}