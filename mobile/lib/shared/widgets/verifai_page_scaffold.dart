import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/navigation/sections.dart';

/// Shared scaffold for every screen pushed on top of [MainNavShell].
///
/// Pushed screens are minor screens: they carry a visible Back control and the
/// screen's own actions. The full destination index and hamburger live on the
/// main shell only, so the top bar stays quiet and navigation follows one
/// pattern.
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
          ...actions,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}