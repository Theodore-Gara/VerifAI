import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

enum VerifAIButtonVariant {
  primary,
  verification,
  secondary,
  ghost,
  gold,
}

class VerifAIButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final VerifAIButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;

  const VerifAIButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = VerifAIButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height = AppSpacing.buttonHeight,
  });

  @override
  State<VerifAIButton> createState() => _VerifAIButtonState();
}

class _VerifAIButtonState extends State<VerifAIButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color bottomDepthColor;
    BorderSide? borderSide;

    switch (widget.variant) {
      case VerifAIButtonVariant.primary:
        backgroundColor = AppColors.primaryNavy;
        foregroundColor = Colors.white;
        bottomDepthColor = AppColors.buttonDepthNavy;
      case VerifAIButtonVariant.verification:
        backgroundColor = AppColors.accentGreen;
        foregroundColor = Colors.white;
        bottomDepthColor = AppColors.buttonDepthGreen;
      case VerifAIButtonVariant.gold:
        backgroundColor = AppColors.gold;
        foregroundColor = Colors.white;
        bottomDepthColor = AppColors.goldDark;
      case VerifAIButtonVariant.secondary:
        backgroundColor = AppColors.surface;
        foregroundColor = AppColors.primaryNavy;
        bottomDepthColor = AppColors.buttonDepthWhite;
        borderSide = const BorderSide(color: AppColors.border, width: 1.5);
      case VerifAIButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textSecondary;
        bottomDepthColor = Colors.transparent;
    }

    final hasDepth = widget.variant != VerifAIButtonVariant.ghost;
    const depthHeight = 3.5;
    final currentOffset = (_isPressed && hasDepth) ? depthHeight : 0.0;

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 18, color: foregroundColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(widget.trailingIcon, size: 18, color: foregroundColor),
              ],
            ],
          );

    if (widget.variant == VerifAIButtonVariant.ghost) {
      return SizedBox(
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        child: TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: widget.height,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(
            top: currentOffset,
            bottom: hasDepth ? (depthHeight - currentOffset) : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: hasDepth
                ? [
                    BoxShadow(
                      color: bottomDepthColor,
                      offset: Offset(0, depthHeight - currentOffset),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              side: borderSide,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}