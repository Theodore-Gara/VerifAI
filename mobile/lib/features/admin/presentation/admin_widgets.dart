import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/providers.dart';

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Text(message ?? 'Could not load this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

/// Human-readable viewer for the admin report endpoints. The data shapes are
/// large and change with content work, so the native portal renders them as
/// labelled sections instead of mirroring every field in a model.
class AdminJsonView extends StatelessWidget {
  const AdminJsonView({super.key, required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is Map) {
      return _mapView(context, adminMap(data));
    }
    if (data is List) {
      final list = data as List;
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _value(context, list[i]),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [_value(context, data)],
    );
  }

  Widget _mapView(BuildContext context, Map<String, dynamic> map) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        for (final entry in map.entries)
          if (entry.key != 'request_id')
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(entry.key),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  _value(context, entry.value),
                ],
              ),
            ),
      ],
    );
  }

  Widget _value(BuildContext context, dynamic value) {
    if (value is Map) {
      final map = adminMap(value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in map.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(_label(entry.key),
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: _value(context, entry.value)),
                ],
              ),
            ),
        ],
      );
    }
    if (value is List) {
      if (value.isEmpty) return const Text('—');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: _value(context, item)),
                ],
              ),
            ),
        ],
      );
    }
    return SelectableText(
      value == null ? '—' : '$value',
      style: const TextStyle(height: 1.4),
    );
  }

  String _label(String key) => key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
}
