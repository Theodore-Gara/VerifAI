import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models/daily_task.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/inline_markdown_text.dart';

class LearningAssistantScreen extends ConsumerStatefulWidget {
  final DailyTask task;

  const LearningAssistantScreen({super.key, required this.task});

  @override
  ConsumerState<LearningAssistantScreen> createState() =>
      _LearningAssistantScreenState();
}

class _LearningAssistantScreenState
    extends ConsumerState<LearningAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<AssistantMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final detail = await ref.read(apiClientProvider).getAssistantSession(widget.task.id);
      if (!mounted) return;
      if (detail.session != null && detail.messages.isNotEmpty) {
        setState(() {
          _messages.addAll(detail.messages.map((m) => AssistantMessage(role: m.role, content: m.content)));
        });
      }
    } catch (_) {
      // Silently fail - start with empty history
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    final userMessage = AssistantMessage(role: 'user', content: text);
    final conversation = [..._messages, userMessage];
    final requestMessages = conversation
        .skip(conversation.length > 8 ? conversation.length - 8 : 0)
        .toList();

    setState(() {
      _messages.add(userMessage);
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();

    try {
      final reply = await ref.read(apiClientProvider).sendAssistantMessage(
            taskId: widget.task.id,
            messages: requestMessages,
          );
      if (!mounted) return;
      setState(() => _messages.add(
            AssistantMessage(role: 'assistant', content: reply),
          ));
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = text;
      });
      showFeedback(
        context,
        FeedbackKind.error,
        'The assistant could not respond. Try again shortly.',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vera', style: AppTypography.textTheme.titleMedium),
            Text(
              widget.task.trackName ?? 'Current verification task',
              style: AppTypography.textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TaskContext(task: widget.task),
            Expanded(
              child: _messages.isEmpty ? _suggestions() : _conversation(),
            ),
            if (_sending) const LinearProgressIndicator(minHeight: 2),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _suggestions() {
    const prompts = [
      'Can you give me a hint?',
      'What skill is this testing?',
      'How can I check this claim?',
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.xl),
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primaryNavy,
          child: const Icon(Icons.support_agent_rounded, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Work through the reasoning.',
          style: AppTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'I can offer a hint or explain the skill this task is practising. I won’t submit the answer for you.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'AI guidance can be imperfect. Verify important claims independently.',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final prompt in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                label: Text(prompt),
                onPressed: _sending ? null : () => _send(prompt),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.border),
                labelStyle: AppTypography.textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _conversation() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final fromAssistant = message.role == 'assistant';
        return Align(
          alignment:
              fromAssistant ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: fromAssistant ? AppColors.surface : AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border:
                  fromAssistant ? Border.all(color: AppColors.border) : null,
            ),
            child: InlineMarkdownText(
              message.content,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: fromAssistant ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask for a hint or explanation',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: _sending ? null : () => _send(),
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}

class _TaskContext extends StatelessWidget {
  final DailyTask task;

  const _TaskContext({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:
            Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.primaryNavy),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
