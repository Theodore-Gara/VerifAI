import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';

/// Tappable page indicator dots for PageView navigation.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onPageSelected,
    // Resolved in build so the indicator follows the active palette.
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageSelected;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return InkWell(
            onTap: () => onPageSelected(index),
            borderRadius: BorderRadius.circular(dotSize * 2),
            child: Padding(
              padding: EdgeInsets.all(spacing / 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? dotSize * 2.5 : dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isActive
                      ? (activeColor ?? AppColors.primaryNavy)
                      : (inactiveColor ?? AppColors.border),
                  borderRadius: BorderRadius.circular(dotSize),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
