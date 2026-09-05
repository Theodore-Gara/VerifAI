import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';

enum VerifAICardVariant {
  elevated,
  outlined,
  filled,
}

class VerifAICard extends StatelessWidget {
  final Widget child;
  final VerifAICardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const VerifAICard({
    super.key,
    required this.child,
    this.variant = VerifAICardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? _getBackgroundColor(),
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
        border: _getBorder(),
        boxShadow: _getShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
        child: card,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case VerifAICardVariant.elevated:
        return AppColors.surface;
      case VerifAICardVariant.outlined:
        return AppColors.surface;
      case VerifAICardVariant.filled:
        return AppColors.background;
    }
  }

  Border? _getBorder() {
    switch (variant) {
      case VerifAICardVariant.elevated:
        return Border.all(color: AppColors.border, width: 1);
      case VerifAICardVariant.outlined:
        return Border.all(color: AppColors.border, width: 1.5);
      case VerifAICardVariant.filled:
        return null;
    }
  }

  List<BoxShadow>? _getShadow() {
    if (variant == VerifAICardVariant.elevated) {
      return const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    }
    return null;
  }
}