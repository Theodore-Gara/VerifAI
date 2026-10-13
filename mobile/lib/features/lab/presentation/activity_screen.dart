import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models.dart';

class ActivityArgs {
  const ActivityArgs({required this.activity, required this.code});
  final LabActivity activity;
  final String code;
}

/// A single recall activity. Reuses the app's controlled-choice layout.
class LabActivityScreen extends ConsumerStatefulWidget {
  const LabActivityScreen({super.key, required this.args});
  final ActivityArgs args;

  @override
  ConsumerState<LabActivityScreen> createState() => _LabActivityScreenState();
}

class _LabActivityScreenState extends ConsumerState<LabActivityScreen> {
  int? _choice;
  bool? _bool;
  final _text = TextEditingController();
  final Map<String, String?> _matching = {};
  late List<String> _order;
  bool _submitting = false;
  LabActivityResult? _result;

  LabActivity get _activity => widget.args.activity;

  @override
  void initState() {
    super.initState();
    _order = List.of(_activity.items);
    if (_activity.type == 'matching') {
      for (final l in _activity.left) {
        _matching[l] = null;
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting || _result != null) return false;
    switch (_activity.type) {
      case 'multiple_choice':
        return _choice != null;
      case 'true_false':
        return _bool != null;
      case 'fill_blank':
        return _text.text.trim().isNotEmpty;
      case 'matching':
        return _matching.length == _activity.left.length && _matching.values.every((v) => v != null);
      case 'ordering':
        return true;
      default:
        return false;
    }
  }

  dynamic _buildResponse() {
    switch (_activity.type) {
      case 'multiple_choice':
        return _choice;
      case 'true_false':
        return _bool;
      case 'fill_blank':
        return _text.text.trim();
      case 'matching':
        return _matching.map((k, v) => MapEntry(k, v ?? ''));
      case 'ordering':
        return _order;
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .submitActivity(_activity.id, response: _buildResponse());
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit. Try again.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Practice question',
            style: AppTypography.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
              AppSpacing.screenPadding, AppSpacing.xxl),
          children: [
            Text(_activity.prompt,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3)),
            const SizedBox(height: AppSpacing.lg),
            ..._body(),
            const SizedBox(height: AppSpacing.lg),
            if (_result == null)
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(_submitting ? 'Checking…' : 'Check answer'),
              )
            else
              _resultPanel(_result!),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (_activity.type) {
      case 'multiple_choice':
        return [
          for (var i = 0; i < _activity.options.length; i++)
            _optionTile(_activity.options[i], _choice == i, () => setState(() => _choice = i)),
        ];
      case 'true_false':
        return [
          _optionTile('True', _bool == true, () => setState(() => _bool = true)),
          _optionTile('False', _bool == false, () => setState(() => _bool = false)),
        ];
      case 'fill_blank':
        return [
          TextField(
            controller: _text,
            enabled: _result == null,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Your answer', border: OutlineInputBorder()),
          ),
        ];
      case 'matching':
        return [
          for (final l in _activity.left)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(l, style: AppTypography.textTheme.bodyMedium)),
                  const SizedBox(width: AppSpacing.sm),
                  DropdownButton<String>(
                    value: _matching[l],
                    hint: const Text('Match'),
                    items: [for (final r in _activity.right) DropdownMenuItem(value: r, child: Text(r))],
                    onChanged: _result != null ? null : (v) => setState(() => _matching[l] = v),
                  ),
                ],
              ),
            ),
        ];
      case 'ordering':
        return [
          Text('Drag into the correct order:', style: AppTypography.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: _result != null
                ? (_, __) {}
                : (fromIndex, toIndex) {
                    setState(() {
                      final item = _order.removeAt(fromIndex);
                      _order.insert(toIndex, item);
                    });
                  },
            children: [
              for (var i = 0; i < _order.length; i++)
                Card(
                  key: ValueKey('$_order[$i]'),
                  child: ListTile(leading: Text('${i + 1}'), title: Text(_order[i])),
                ),
            ],
          ),
        ];
      default:
        return [];
    }
  }

  Widget _optionTile(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: _result != null ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentLight.withValues(alpha: .7) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: selected ? AppColors.accentGreen : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20, color: selected ? AppColors.accentGreen : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultPanel(LabActivityResult result) {
    final ok = result.passed;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (ok ? AppColors.accentGreen : AppColors.warning).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: (ok ? AppColors.accentGreen : AppColors.warning).withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: ok ? AppColors.accentGreen : AppColors.goldDark),
              const SizedBox(width: 8),
              Text(ok ? 'Correct' : 'Not quite',
                  style: AppTypography.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
              const Spacer(),
              if (result.xpEarned > 0) Text('+${result.xpEarned} XP',
                  style: AppTypography.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentGreen)),
            ],
          ),
          if (result.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(result.explanation, style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ),
              if (!ok) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() {
                      _result = null;
                      _choice = null;
                      _bool = null;
                    }),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
