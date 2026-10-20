import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// One row in a hub screen. A hub groups the destinations that used to be
/// scattered across the drawer and full-screen routes, so the bottom dock only
/// ever carries five top-level areas.
class HubEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;

  const HubEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
    this.onTap,
  }) : assert(route != null || onTap != null,
            'A hub entry needs either a route or an onTap handler.');
}

class HubSectionTitle extends StatelessWidget {
  final String label;
  const HubSectionTitle(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          fontSize: 11,
        ),
      ),
    );
  }
}

class HubTile extends StatelessWidget {
  final HubEntry entry;
  const HubTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label: '${entry.title}. ${entry.subtitle}',
        excludeSemantics: true,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () {
              HapticFeedback.selectionClick();
              if (entry.onTap != null) {
                entry.onTap!();
              } else if (entry.route != null) {
                context.push(entry.route!);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(entry.icon,
                        size: 21, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
