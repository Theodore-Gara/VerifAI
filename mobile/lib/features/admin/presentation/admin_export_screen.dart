import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';

class AdminExportScreen extends ConsumerStatefulWidget {
  const AdminExportScreen({super.key});

  @override
  ConsumerState<AdminExportScreen> createState() => _AdminExportScreenState();
}

class _AdminExportScreenState extends ConsumerState<AdminExportScreen> {
  String? _busy;

  Future<void> _export(String label, String path) async {
    setState(() => _busy = path);
    try {
      final csv = await ref.read(apiClientProvider).adminTextRequest(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 600,
            height: 360,
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Copy CSV'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(classifyError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const exports = [
      ('Users CSV', 'export/users.csv'),
      ('Attempts CSV', 'export/attempts.csv'),
      ('Track progress CSV', 'export/tracks.csv'),
    ];
    return AdminToolScaffold(
      title: 'CSV exports',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          AdminCard(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderColor: AppColors.warning.withValues(alpha: 0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Exports contain personal data (emails, progress). Handle '
                    'them according to your retention policy. Every download is '
                    'recorded in the audit log.',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final export in exports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AdminCard(
                onTap: _busy == null
                    ? () => _export(export.$1, export.$2)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.download_rounded,
                          size: 20, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            export.$1,
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            export.$2,
                            style:
                                AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_busy == export.$2)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
