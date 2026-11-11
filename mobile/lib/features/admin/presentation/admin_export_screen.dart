import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';

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
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Exports contain personal data (emails, progress). Handle them according to your retention policy.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final export in exports)
            Card(
              child: ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(export.$1),
                subtitle: Text(export.$2),
                trailing: _busy == export.$2
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right_rounded),
                onTap:
                    _busy == null ? () => _export(export.$1, export.$2) : null,
              ),
            ),
        ],
      ),
    );
  }
}
