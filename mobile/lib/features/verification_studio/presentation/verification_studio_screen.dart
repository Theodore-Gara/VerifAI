import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/verification_studio/presentation/verification_result_screen.dart';
import 'package:verifai/features/verification_studio/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

/// Verification Studio — Vera verifies text, documents, links and citations.
class VerificationStudioScreen extends ConsumerStatefulWidget {
  const VerificationStudioScreen({super.key});

  @override
  ConsumerState<VerificationStudioScreen> createState() => _State();
}

class _State extends ConsumerState<VerificationStudioScreen> {
  static const _kinds = {
    'document': 'Document',
    'claim': 'Claim',
    'ai_response': 'AI response',
    'source': 'Source',
  };

  String _kind = 'document';
  final List<VerificationSourceInput> _sources = [];
  final _text = TextEditingController();
  final _url = TextEditingController();
  final _citation = TextEditingController();
  final _context = TextEditingController();
  bool _webSearch = true;
  bool _running = false;

  @override
  void dispose() {
    _text.dispose();
    _url.dispose();
    _citation.dispose();
    _context.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await FilePicker.platform.pickFiles(withData: true);
      final file = picked?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
      const maxBytes = 10 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        if (mounted) showFeedback(context, FeedbackKind.error, 'Document must be 10MB or smaller.');
        return;
      }
      setState(() => _sources.add(VerificationSourceInput(
            type: 'document',
            name: file.name,
            mime: _mimeFor(file.extension),
            base64: base64Encode(bytes),
          )));
    } catch (_) {
      if (mounted) showFeedback(context, FeedbackKind.error, 'Could not read that file.');
    }
  }

  String _mimeFor(String? ext) => switch ((ext ?? '').toLowerCase()) {
        'pdf' => 'application/pdf',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'md' => 'text/markdown',
        _ => 'text/plain',
      };

  void _addUrl() {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _sources.add(VerificationSourceInput(type: 'url', url: url));
      _url.clear();
    });
  }

  void _addCitation() {
    final citation = _citation.text.trim();
    if (citation.isEmpty) return;
    setState(() {
      _sources.add(VerificationSourceInput(type: 'citation', text: citation));
      _citation.clear();
    });
  }

  Future<void> _run() async {
    final sources = <VerificationSourceInput>[
      if (_text.text.trim().isNotEmpty) VerificationSourceInput(type: 'text', text: _text.text.trim()),
      ..._sources,
    ];
    if (sources.isEmpty && _context.text.trim().isEmpty) {
      showFeedback(context, FeedbackKind.error, 'Add some text, a document, a link or a citation first.');
      return;
    }
    setState(() => _running = true);
    try {
      final result = await ref.read(apiClientProvider).analyzeVerification(
            kind: _kind,
            context: _context.text.trim().isEmpty ? null : _context.text.trim(),
            sources: sources,
            webSearch: _webSearch,
          );
      if (!mounted) return;
      setState(() {
        _text.clear();
        _context.clear();
        _sources.clear();
      });
      ref.invalidate(verificationHistoryProvider);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerificationResultScreen(result: result),
      ));
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, 'Verification failed. $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(verificationHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Verification Studio',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
            AppSpacing.screenPadding, AppSpacing.xxl),
        children: [
          Text('Vera checks a claim, document, AI answer or source and reports what needs review.',
              style: AppTypography.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: AppSpacing.lg),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'What are you verifying?', border: OutlineInputBorder()),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _kind,
                items: [for (final e in _kinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _kind = v ?? 'document'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
                labelText: 'Text to verify', hintText: 'Paste a claim, an AI answer, or content…',
                border: OutlineInputBorder(), alignLabelWithHint: true),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'Link', hintText: 'https://…', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(onPressed: _addUrl, icon: const Icon(Icons.add_link_rounded), tooltip: 'Add link'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _citation,
                  decoration: const InputDecoration(labelText: 'Citation', hintText: 'e.g. POPIA section 22', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(onPressed: _addCitation, icon: const Icon(Icons.manage_search_rounded), tooltip: 'Look up citation'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload a document (PDF, DOCX, TXT, MD)'),
          ),
          if (_sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var i = 0; i < _sources.length; i++) _sourceChip(i),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _context,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Context (optional)', hintText: 'Anything Vera should know',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: _webSearch,
            onChanged: (v) => setState(() => _webSearch = v ?? true),
            title: const Text('Search the web for evidence'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.fact_check_rounded),
            label: Text(_running ? 'Verifying…' : 'Run verification'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('RECENT VERIFICATIONS',
              style: AppTypography.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: .5)),
          const SizedBox(height: AppSpacing.sm),
          historyAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator()),
            error: (e, _) => Text('History unavailable.',
                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            data: (items) => items.isEmpty
                ? Text('No verifications yet.',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))
                : Column(
                    children: [
                      for (final r in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined, color: AppColors.primaryNavy),
                          title: Text(r.documentName ?? _kinds[r.kind] ?? r.kind),
                          subtitle: Text(r.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => VerificationResultScreen(result: r))),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(int index) {
    final s = _sources[index];
    final label = switch (s.type) {
      'url' => 'Link: ${s.url}',
      'citation' => 'Citation: ${s.text}',
      'document' => 'Doc: ${s.name}',
      _ => s.text ?? s.type,
    };
    return InputChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onDeleted: () => setState(() => _sources.removeAt(index)),
    );
  }
}
