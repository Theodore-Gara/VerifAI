import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// One destination in the admin navigation.
class AdminNavItem {
  const AdminNavItem(this.label, this.icon, {this.badge = 0});

  final String label;
  final IconData icon;

  /// Unread count badge. Zero means no badge.
  final int badge;
}

/// The admin bottom navigation.
///
/// Material's NavigationBar paints its indicator behind the icon, so a
/// selected tab reads as a coloured pill with an unstyled label next to it.
/// This bar puts the colour where the eye expects it: the selected icon and
/// its label both take the accent, sitting on a soft pill, with a rule along
/// the top edge to mark the active tab.
class AdminNavBar extends StatelessWidget {
  const AdminNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavDestination(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGreen : AppColors.textSecondary;

    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 30,
          decoration: BoxDecoration(
            color:
                selected ? AppColors.accentGreen.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, size: 21, color: color),
        ),
        if (item.badge > 0)
          Positioned(
            right: 2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Text(
                '${item.badge > 99 ? '99+' : item.badge}',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A rule along the top marks the active tab without stealing
            // attention from the icon itself.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            icon,
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wide-screen equivalent of [AdminNavBar].
class AdminNavRail extends StatelessWidget {
  const AdminNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: _RailDestination(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGreen : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.accentGreen.withValues(alpha: 0.10) : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected
                  ? AppColors.accentGreen.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 22, color: color),
                  if (item.badge > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border:
                              Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text(
                          '${item.badge > 99 ? '99+' : item.badge}',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
