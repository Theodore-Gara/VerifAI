import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// The kind of feedback a banner communicates. Drives the color treatment.
enum FeedbackKind { success, error, info }

/// A professional, floating feedback banner. Replaces raw SnackBars app-wide
/// so success, error and informational feedback share one calm, branded style.
///
/// Usage:
/// ```dart
/// showFeedback(context, FeedbackKind.success, 'Your progress was saved.');
/// showFeedback(
///   context,
///   FeedbackKind.error,
///   'We could not submit your answer.',
///   actionLabel: 'Retry',
///   onAction: (hide) => hide(),
/// );
/// ```
void showFeedback(
  BuildContext context,
  FeedbackKind kind,
  String message, {
  String? actionLabel,
  void Function(VoidCallback hide)? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final FeedbackOverlayState? host = FeedbackOverlay.maybeOf(context);
  if (host != null) {
    host.show(
      kind,
      message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
    return;
  }

  // No host (e.g. plain screen without an overlay or a test harness): render
  // through the ScaffoldMessenger as a floating, themed widget — never the
  // default dark Material snackbar strip.
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: FeedbackBanner(
        kind: kind,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () => onAction(messenger.hideCurrentSnackBar),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
    ),
  );
}

/// Overlay host that renders banners floating above its child. Wrap a
/// [Scaffold] body (or the whole app) with it so deep call sites can raise
/// feedback without owning the Scaffold.
class FeedbackOverlay extends StatefulWidget {
  const FeedbackOverlay({super.key, required this.child});

  final Widget child;

  static FeedbackOverlayState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<FeedbackOverlayState>();

  @override
  State<FeedbackOverlay> createState() => FeedbackOverlayState();
}

class FeedbackOverlayState extends State<FeedbackOverlay> {
  _BannerPayload? _current;
  int _sequence = 0;

  void show(
    FeedbackKind kind,
    String message, {
    String? actionLabel,
    void Function(VoidCallback hide)? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    final int token = ++_sequence;
    final VoidCallback hide = onAction == null
        ? () => dismiss(token)
        : () => onAction(() => dismiss(token));
    setState(() {
      _current = _BannerPayload(
        kind: kind,
        message: message,
        actionLabel: actionLabel,
        hide: hide,
        sequence: token,
      );
    });
    if (duration != Duration.zero) {
      Future<void>.delayed(duration, () => dismiss(token));
    }
  }

  void dismiss(int token) {
    if (!mounted || _current?.sequence != token) return;
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    final _BannerPayload? payload = _current;
    if (payload == null) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: FeedbackBanner(
            kind: payload.kind,
            message: payload.message,
            actionLabel: payload.actionLabel,
            onAction: payload.hide,
          ),
        ),
      ],
    );
  }
}

class _BannerPayload {
  const _BannerPayload({
    required this.kind,
    required this.message,
    required this.sequence,
    required this.hide,
    this.actionLabel,
  });

  final FeedbackKind kind;
  final String message;
  final int sequence;
  final String? actionLabel;
  final VoidCallback hide;
}

/// The visual banner itself. Also usable inline on a screen for persistent
/// status messages.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.message,
    this.kind = FeedbackKind.info,
    this.actionLabel,
    this.onAction,
  });

  final FeedbackKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (:Color accent, :Color soft) = switch (kind) {
      FeedbackKind.success => (
          accent: AppColors.accentGreen,
          soft: AppColors.accentLight,
        ),
      FeedbackKind.error => (
          accent: AppColors.error,
          soft: const Color(0xFFFDECEC),
        ),
      FeedbackKind.info => (
          accent: AppColors.primaryNavy,
          soft: AppColors.background,
        ),
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  minimumSize: const Size(0, 34),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                child: Text(actionLabel!),
              )
            else
              GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
