import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/vera/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

/// Vera — the app-wide AI assistant with memory and session history.
class VeraAssistantScreen extends ConsumerStatefulWidget {
  const VeraAssistantScreen({super.key});

  @override
  ConsumerState<VeraAssistantScreen> createState() => _VeraAssistantScreenState();
}

class _VeraAssistantScreenState extends ConsumerState<VeraAssistantScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final List<AssistantMessage> _messages = [];
  int? _sessionId;
  bool _sending = false;
  bool _webSearch = false;
  bool _greeted = false;
  String _streaming = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGreet());
  }

  // Vera greets out loud on a new/empty chat.
  void _maybeGreet() {
    if (_greeted || !mounted) return;
    _greeted = true;
    _speakGreeting();
  }

  Future<void> _speakGreeting() async {
    try {
      await _tts.stop();
      await _tts.setLanguage('en-GB');
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.speak("Hi I'm Vera, your AI assistant. What are we doing today.");
    } catch (_) {
      // Device speech is unavailable; the written greeting still shows.
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _tts.stop();
    super.dispose();
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _sessionId = null;
      _streaming = '';
    });
    _greeted = false;
    _maybeGreet();
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openSession(VeraSession session) async {
    Navigator.of(context).pop(); // close drawer
    try {
      final detail = await ref.read(apiClientProvider).getVeraSession(session.id);
      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _messages
          ..clear()
          ..addAll(detail.messages.map((m) => AssistantMessage(role: m.role, content: m.content)));
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, 'Could not open that conversation.');
    }
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    final userMessage = AssistantMessage(role: 'user', content: text);
    final conversation = [..._messages, userMessage];
    final requestMessages =
        conversation.skip(conversation.length > 16 ? conversation.length - 16 : 0).toList();

    setState(() {
      _messages.add(userMessage);
      _sending = true;
      _streaming = '';
      _input.clear();
    });
    _scrollToBottom();

    try {
      final buffer = StringBuffer();
      await for (final delta in ref.read(apiClientProvider).streamVeraMessage(
            sessionId: _sessionId,
            messages: requestMessages,
            webSearch: _webSearch,
            onSessionId: (id) => _sessionId = id,
          )) {
        buffer.write(delta);
        if (mounted) setState(() => _streaming = buffer.toString());
        _scrollToBottom();
      }
      if (!mounted) return;
      setState(() {
        if (buffer.isNotEmpty) {
          _messages.add(AssistantMessage(role: 'assistant', content: buffer.toString()));
        }
        _streaming = '';
      });
      ref.invalidate(veraSessionsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = text;
        _streaming = '';
      });
      showFeedback(context, FeedbackKind.error, 'Vera could not respond. Try again shortly.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const CircleAvatar(
                radius: 15, backgroundColor: AppColors.primaryNavy,
                child: Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white)),
            const SizedBox(width: 10),
            Text('Vera',
                style: AppTypography.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'New chat',
              onPressed: _newChat,
              icon: const Icon(Icons.edit_square, color: AppColors.primaryNavy)),
          IconButton(
              tooltip: 'History',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.history_rounded, color: AppColors.primaryNavy)),
        ],
      ),
      endDrawer: _sessionsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty && _streaming.isEmpty ? _welcome() : _conversation(),
            ),
            if (_sending && _streaming.isEmpty) const LinearProgressIndicator(minHeight: 2),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _sessionsDrawer() {
    final sessionsAsync = ref.watch(veraSessionsProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Conversations',
                  style: AppTypography.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New chat'),
              onTap: _newChat,
            ),
            const Divider(height: 1),
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('Could not load conversations.')),
                data: (sessions) => sessions.isEmpty
                    ? const Center(child: Text('No conversations yet.'))
                    : ListView(
                        children: [
                          for (final s in sessions)
                            ListTile(
                              selected: s.id == _sessionId,
                              leading: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                              title: Text(s.title ?? 'Conversation',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${s.messageCount} messages',
                                  style: AppTypography.textTheme.labelSmall),
                              onTap: () => _openSession(s),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    final tipsAsync = ref.watch(veraTipsProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Center(
          child: CircleAvatar(
              radius: 30, backgroundColor: AppColors.primaryNavy,
              child: Icon(Icons.auto_awesome_rounded, size: 30, color: Colors.white)),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text('Hi, I am Vera.',
              style: AppTypography.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Ask me anything — I know your progress, your lessons and your rewards, and I can '
            'look things up on the web to help you verify a claim.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: AppSpacing.lg),
        tipsAsync.maybeWhen(
          data: (tips) => Column(
            children: [
              for (final t in tips)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          style: AppTypography.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                      const SizedBox(height: 2),
                      Text(t.body, style: AppTypography.textTheme.bodySmall?.copyWith(height: 1.4)),
                    ],
                  ),
                ),
            ],
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            ('Which reward should I save for?', false),
            ('What should I focus on next?', false),
            ('Please verify: an AI gave me this claim…', true),
          ]
              .map((c) => ActionChip(
                    label: Text(c.$1),
                    onPressed: () {
                      if (c.$2) setState(() => _webSearch = true);
                      _send(c.$1);
                    },
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _conversation() {
    final items = <Widget>[
      for (final m in _messages) _bubble(m.content, m.role == 'assistant'),
      if (_streaming.isNotEmpty) _bubble(_streaming, true),
    ];
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: items,
    );
  }

  Widget _bubble(String text, bool assistant) => Align(
        alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: assistant ? AppColors.surface : AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: assistant ? Border.all(color: AppColors.border) : null,
          ),
          child: Text(text,
              style: AppTypography.textTheme.bodyMedium
                  ?.copyWith(color: assistant ? AppColors.textPrimary : Colors.white, height: 1.5)),
        ),
      );

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask Vera…',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                suffixIcon: _WebSearchButton(
                    active: _webSearch, onTap: () => setState(() => _webSearch = !_webSearch)),
                suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    borderSide: BorderSide(
                        color: _webSearch ? AppColors.electricMint : AppColors.borderFocus)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: _sending ? null : () => _send(),
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Circular web-search toggle that sits on the right of the input, beside send.
class _WebSearchButton extends StatelessWidget {
  const _WebSearchButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: active ? 'Web search on' : 'Search the web',
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.electricMint.withValues(alpha: .12) : Colors.transparent,
                border: Border.all(
                    color: active ? AppColors.electricMint : AppColors.border,
                    width: active ? 1.8 : 1.2),
              ),
              child: Icon(Icons.travel_explore_rounded,
                  size: 18, color: active ? AppColors.electricMint : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
