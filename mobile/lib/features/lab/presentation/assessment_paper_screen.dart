import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/lab/presentation/assessment_instructions_screen.dart';
import 'package:verifai/shared/models.dart';

class PaperArgs {
  const PaperArgs({required this.code, required this.start});
  final String code;
  final LabAssessmentStart start;
}

/// A timed, paginated capstone paper with a sticky countdown.
class LabAssessmentPaperScreen extends ConsumerStatefulWidget {
  const LabAssessmentPaperScreen({super.key, required this.args});
  final PaperArgs args;

  @override
  ConsumerState<LabAssessmentPaperScreen> createState() =>
      _LabAssessmentPaperScreenState();
}

class _LabAssessmentPaperScreenState
    extends ConsumerState<LabAssessmentPaperScreen> {
  final _pageController = PageController();
  final Map<int, dynamic> _answers = {};
  int _page = 0;
  Timer? _ticker;
  late int _remaining;
  bool _submitting = false;
  bool _submitted = false;

  List<LabAssessmentQuestion> get _questions => widget.args.start.questions;
  String get _code => widget.args.code;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_syncPageIndex);
    _remaining = _secondsLeft();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeft();
      setState(() => _remaining = left);
      if (left <= 0) _submit(auto: true);
    });
  }

  void _syncPageIndex() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _page && mounted) {
      setState(() => _page = rounded);
    }
  }

  int _secondsLeft() {
    final expires = DateTime.tryParse(widget.args.start.expiresAt);
    if (expires == null) return widget.args.start.timeLimitSeconds;
    final left = expires.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.removeListener(_syncPageIndex);
    _pageController.dispose();
    super.dispose();
  }

  Map<int, dynamic> _buildPayload() {
    final payload = <int, dynamic>{};
    for (final q in _questions) {
      final a = _answers[q.id];
      switch (q.type) {
        case 'multiple_choice':
          if (a is int) payload[q.id] = a;
          break;
        case 'true_false':
          if (a is bool) payload[q.id] = a;
          break;
        case 'fill_blank':
          if (a is String && a.trim().isNotEmpty) payload[q.id] = a.trim();
          break;
        case 'multi_select':
          if (a is Set<int>) payload[q.id] = (a.toList()..sort());
          break;
        case 'numeric':
          if (a is List<String>) {
            payload[q.id] = a.map((e) => num.tryParse(e) ?? 0).toList();
          } else if (a is String && a.trim().isNotEmpty) {
            payload[q.id] = num.tryParse(a.trim()) ?? a.trim();
          }
          break;
        case 'matching':
          if (a is Map) {
            payload[q.id] = a.map((k, v) => MapEntry('$k', v ?? ''));
          }
          break;
        case 'ordering':
          if (a is List) {
            payload[q.id] = a;
          }
          break;
        case 'extended_response':
          if (a is String && a.trim().isNotEmpty) payload[q.id] = a.trim();
          break;
      }
    }
    return payload;
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting || _submitted) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(apiClientProvider).submitAssessment(
            _code,
            attemptId: widget.args.start.attemptId,
            answers: _buildPayload(),
          );
      _submitted = true;
      if (!mounted) return;
      ref.invalidate(dashboardProvider);
      context.go('/ai-lab/assessments/$_code',
          extra: AssessmentOutcome(
              result: result, attemptId: widget.args.start.attemptId));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auto
              ? 'Time is up but the paper could not be submitted. Please try again.'
              : 'Could not submit the paper. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text('Assessment paper',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _timer(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  onPageChanged: (i) {
                    if (i != _page) setState(() => _page = i);
                  },
                  itemBuilder: (context, i) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                        AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
                    child: _questionView(_questions[i], i),
                  ),
                ),
              ),
              _navBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timer() {
    final critical = _remaining <= 120;
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
      color: critical
          ? AppColors.warning.withValues(alpha: .12)
          : AppColors.primaryNavy,
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 18, color: critical ? AppColors.goldDark : Colors.white),
          const SizedBox(width: 8),
          Text('$m:$s',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: critical ? AppColors.goldDark : Colors.white,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('Question ${_page + 1} of ${_questions.length}',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: critical ? AppColors.goldDark : Colors.white70)),
        ],
      ),
    );
  }

  Widget _navBar() {
    final last = _page == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.md),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _page > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _submitting
                ? null
                : () {
                    if (last) {
                      _submit();
                    } else {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut);
                    }
                  },
            icon: Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 17),
            label: Text(
                _submitting ? 'Submitting…' : (last ? 'Submit paper' : 'Next')),
          ),
        ],
      ),
    );
  }

  Widget _questionView(LabAssessmentQuestion q, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question ${index + 1} · ${q.marks} marks',
            style: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        if (q.scenario != null && q.scenario!.isNotEmpty) ...[
          _scenario(q.scenario!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (q.codeLines.isNotEmpty) ...[
          _codeBlock(q.codeLines),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(q.prompt,
            style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.35)),
        const SizedBox(height: AppSpacing.lg),
        ..._answerWidgets(q),
      ],
    );
  }

  Widget _scenario(String text) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border)),
        child: Text(text,
            style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
      );

  Widget _codeBlock(List<String> lines) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Text(lines.join('\n'),
            style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
                fontSize: 12,
                height: 1.5)),
      );

  List<Widget> _answerWidgets(LabAssessmentQuestion q) {
    switch (q.type) {
      case 'multiple_choice':
        return [
          for (var i = 0; i < q.options.length; i++)
            _optionTile(q.options[i], _answers[q.id] == i,
                () => setState(() => _answers[q.id] = i)),
        ];
      case 'true_false':
        return [
          _optionTile('True', _answers[q.id] == true,
              () => setState(() => _answers[q.id] = true)),
          _optionTile('False', _answers[q.id] == false,
              () => setState(() => _answers[q.id] = false)),
        ];
      case 'multi_select':
        final set = (_answers[q.id] as Set<int>?) ?? <int>{};
        return [
          for (var i = 0; i < q.options.length; i++)
            CheckboxListTile(
              value: set.contains(i),
              onChanged: (v) => setState(() {
                final s = Set<int>.from(set);
                if (v == true) {
                  s.add(i);
                } else {
                  s.remove(i);
                }
                _answers[q.id] = s;
              }),
              title: Text(q.options[i]),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ];
      case 'fill_blank':
        return [
          TextFormField(
            initialValue: _answers[q.id] as String? ?? '',
            onChanged: (v) => _answers[q.id] = v,
            decoration: const InputDecoration(
                hintText: 'Your answer', border: OutlineInputBorder()),
          ),
        ];
      case 'numeric':
        if (q.parts.isNotEmpty) {
          final vals = (_answers[q.id] as List<String>?) ??
              List<String>.filled(q.parts.length, '');
          return [
            for (var i = 0; i < q.parts.length; i++) ...[
              Text((q.parts[i]['label'] ?? 'Part ${i + 1}').toString(),
                  style: AppTypography.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text((q.parts[i]['prompt'] ?? '').toString(),
                  style: AppTypography.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: vals[i],
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final list = List<String>.from(
                      (_answers[q.id] as List<String>?) ??
                          List<String>.filled(q.parts.length, ''));
                  list[i] = v;
                  _answers[q.id] = list;
                },
                decoration: const InputDecoration(
                    hintText: 'Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ];
        }
        return [
          TextFormField(
            initialValue: _answers[q.id] as String? ?? '',
            keyboardType: TextInputType.number,
            onChanged: (v) => _answers[q.id] = v,
            decoration: const InputDecoration(
                hintText: 'Number', border: OutlineInputBorder()),
          ),
        ];
      case 'matching':
        final map = (_answers[q.id] as Map<String, String?>?) ??
            {for (final l in q.left) l: null};
        return [
          for (final l in q.left)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text(l, style: AppTypography.textTheme.bodyMedium)),
                  const SizedBox(width: AppSpacing.sm),
                  DropdownButton<String>(
                    value: map[l],
                    hint: const Text('Match'),
                    items: [
                      for (final r in q.right)
                        DropdownMenuItem(value: r, child: Text(r))
                    ],
                    onChanged: (v) => setState(() {
                      final m = Map<String, String?>.from(map);
                      m[l] = v;
                      _answers[q.id] = m;
                    }),
                  ),
                ],
              ),
            ),
        ];
      case 'ordering':
        final items =
            (_answers[q.id] as List<String>?) ?? List<String>.from(q.items);
        return [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: (oldIndex, newIndex) => setState(() {
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              _answers[q.id] = items;
            }),
            children: [
              for (var i = 0; i < items.length; i++)
                Card(
                    key: ValueKey('$i-${items[i]}'),
                    child: ListTile(
                        leading: Text('${i + 1}'), title: Text(items[i]))),
            ],
          ),
        ];
      case 'extended_response':
        return [
          TextFormField(
            initialValue: _answers[q.id] as String? ?? '',
            minLines: 6,
            maxLines: 12,
            onChanged: (v) => _answers[q.id] = v,
            decoration: const InputDecoration(
                hintText: 'Write your answer…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true),
          ),
          if (q.wordLimit != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Aim for ${q.wordLimit!['min'] ?? ''}-${q.wordLimit!['max'] ?? ''} words.',
                  style: AppTypography.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
        ];
      default:
        return [const Text('Unsupported question type.')];
    }
  }

  Widget _optionTile(String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentLight.withValues(alpha: .7)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: selected ? AppColors.accentGreen : AppColors.border,
                  width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected
                        ? AppColors.accentGreen
                        : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child:
                        Text(label, style: AppTypography.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      );

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the paper?'),
        content: const Text(
            'Your progress on this attempt is not saved until you submit.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true && mounted) {
      _ticker?.cancel();
      context.go('/ai-lab/assessments/$_code');
    }
  }
}
