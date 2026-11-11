import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/providers.dart';

/// Shared primitives for the native admin portal.
///
/// The portal grew screen by screen and every screen ended up with its own
/// idea of a card, a row and a dialog. These widgets are the single place
/// that defines the look, so padding, hierarchy and rhythm stay consistent
/// as screens are added.

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

/// Empty state for a list that has nothing in it.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card with the portal's standard inner padding and border.
///
/// Every list row and panel in the admin app uses this, so cards never sit
/// flush against each other and content always has room to breathe.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      ),
    );
  }
}

/// A titled block of content.
///
/// The title is the page's structural element: it says what the group of
/// rows underneath is, so a long screen can be scanned rather than read.
class AdminSection extends StatelessWidget {
  const AdminSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.xl),
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AdminCard(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _withGaps(children),
            ),
          ),
        ],
      ),
    );
  }

  /// Rows inside a section are separated by a hairline, not by stacking
  /// separate cards: one card per section keeps the page calm.
  static List<Widget> _withGaps(List<Widget> children) {
    if (children.length < 2) return children;
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        out.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(height: 1, thickness: 1),
        ));
      }
      out.add(children[i]);
    }
    return out;
  }
}

/// A label/value pair.
///
/// The value is the subject: it is set larger and bolder. The label is
/// metadata and stays small and quiet underneath.
class AdminDataRow extends StatelessWidget {
  const AdminDataRow({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.leading,
    this.trailing,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? detail;
  final Widget? leading;
  final Widget? trailing;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
    return content;
  }
}

/// A big number with a small label underneath.
class AdminStatTile extends StatelessWidget {
  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.detail,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color ?? AppColors.accentGreen),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small status pill: a coloured dot and a word.
class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    Color? color,
  }) : color = color ?? _defaultPillColor;

  static const Color _defaultPillColor = Color(0xFF176B4D);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal bar showing a proportion, for rates and counts.
class AdminProportionBar extends StatelessWidget {
  const AdminProportionBar({
    super.key,
    required this.value,
    required this.max,
    Color? color,
  }) : color = color ?? _defaultBarColor;

  static const Color _defaultBarColor = Color(0xFF176B4D);

  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final factor = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 6,
        color: AppColors.border.withValues(alpha: 0.6),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search field plus filters, on one line with consistent spacing.
class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          children[i],
        ],
      ],
    );
  }
}

/// A dialog body whose fields always have room between them.
///
/// The admin forms are the worst offender for cramped layout: a Column of
/// fields with no gap renders as one solid block. Every form goes through
/// this so the rhythm is the same everywhere.
class AdminDialogBody extends StatelessWidget {
  const AdminDialogBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          children[i],
        ],
      ],
    );
  }
}

/// A short helper line under a dialog field.
class AdminDialogHint extends StatelessWidget {
  const AdminDialogHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
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
        itemBuilder: (context, i) => AdminCard(
          child: _value(context, list[i]),
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
