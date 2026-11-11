import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';

/// Shown while a sign-in waits on the backend. Render's free tier sleeps when
/// idle, so the first request after a quiet spell can take up to a minute;
/// without this the button spinner alone reads as a frozen app.
class AuthProgressNote extends StatelessWidget {
  const AuthProgressNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Connecting to the server. If it has been idle, this can take up '
              'to a minute.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
