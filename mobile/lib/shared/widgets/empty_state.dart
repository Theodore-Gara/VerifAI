import 'package:flutter/material.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VerifAIButtonVariant actionVariant;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionVariant = VerifAIButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              VerifAIButton(
                label: actionLabel!,
                variant: actionVariant,
                isFullWidth: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
      actionVariant: VerifAIButtonVariant.primary,
    );
  }
}

class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No internet connection',
      message: 'Please check your connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
      actionVariant: VerifAIButtonVariant.primary,
    );
  }
}

/// Full-area error state that picks the right message for the failure:
/// offline, timeout, expired session or a generic error. Scrollable so that a
/// surrounding [RefreshIndicator] still works while an error is showing
class AsyncErrorView extends StatelessWidget {
  final Object error;
  final String fallbackMessage;
  final VoidCallback? onRetry;

  const AsyncErrorView({
    super.key,
    required this.error,
    this.fallbackMessage = 'Something went wrong. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failure = classifyError(error);
    final Widget content;

    switch (failure.kind) {
      case ApiFailureKind.offline:
        content = EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'You\'re offline',
          message: failure.message,
          actionLabel: onRetry != null ? 'Retry' : null,
          onAction: onRetry,
        );
      case ApiFailureKind.timeout:
        content = EmptyState(
          icon: Icons.timer_off_outlined,
          title: 'Taking too long',
          message: failure.message,
          actionLabel: onRetry != null ? 'Try Again' : null,
          onAction: onRetry,
        );
      case ApiFailureKind.unauthorized:
        // The auth interceptor signs the user out and the router redirects to login, so there is nothing to retry here.
        content = EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Session expired',
          message: failure.message,
        );
      case ApiFailureKind.client:
        content = ErrorState(message: failure.message);
      case ApiFailureKind.server:
      case ApiFailureKind.unknown:
        content = ErrorState(
          message: failure.kind == ApiFailureKind.server
              ? failure.message
              : fallbackMessage,
          onRetry: onRetry,
        );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Compact error row for a section of a screen (the rest of the screen keeps working). Shows offline / timeout / generic copy with an optional retry.
class InlineErrorCard extends StatelessWidget {
  final Object error;
  final String fallbackMessage;
  final VoidCallback? onRetry;

  const InlineErrorCard({
    super.key,
    required this.error,
    this.fallbackMessage = 'Something went wrong. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failure = classifyError(error);
    final message = failure.kind == ApiFailureKind.unknown
        ? fallbackMessage
        : failure.message;
    final icon = failure.isOffline
        ? Icons.wifi_off_rounded
        : failure.isTimeout
            ? Icons.timer_off_outlined
            : Icons.error_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.error, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onRetry != null && failure.isRetryable)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
