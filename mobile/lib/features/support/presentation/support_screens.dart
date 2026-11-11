import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/support/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/inline_markdown_text.dart';
import 'package:verifai/shared/widgets/verifai_page_scaffold.dart';

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _SupportHero extends StatelessWidget {
  const _SupportHero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryFill, AppColors.greenFill],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(eyebrow,
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xFFE1EAE4), height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text, {this.size = 14});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            color: AppColors.textSecondary, height: 1.55, fontSize: size),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.accentGreen),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: Text(label,
              style: TextStyle(
                  color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
          onTap: onTap,
        ),
      );
}

class _SupportError extends StatelessWidget {
  const _SupportError({required this.onRetry, this.message});
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
        Text(message ?? 'Could not load this page.',
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

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------

class AboutVerifaiScreen extends ConsumerWidget {
  const AboutVerifaiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(supportAboutProvider);
    return VerifaiPageScaffold(
      title: 'About Us',
      body: aboutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SupportError(
          message: 'Could not load the About page.',
          onRetry: () => ref.invalidate(supportAboutProvider),
        ),
        data: (about) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            _SupportHero(
              eyebrow: 'WELCOME TO VERIFAI',
              title: about.title,
              subtitle:
                  'A learning and verification experience helping people understand artificial intelligence, question its outputs and use it responsibly.',
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 24),
            for (final section in _aboutSections(about.data))
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.$1,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    InlineMarkdownText(section.$2,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                            fontSize: 14)),
                  ],
                ),
              ),
            Text('Meet the team behind VerifAI',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const _BodyText(
                'VerifAI is brought to life by a collaborative team working to make responsible AI learning practical, accessible and meaningful.'),
            const SizedBox(height: 14),
            for (final name in const [
              'Lawandle Naledi Mvelase',
              'Mpho Mokoena',
              'Theodore Nangara',
              'Vusani Mludzi',
              'Meshaque Kalonji',
            ]) ...[
              _SectionCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentLight,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.accentGreen),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(name,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.support_agent_rounded,
              title: 'Need assistance?',
              subtitle: 'Visit Help & Support or send us a query.',
              label: 'Get help',
              onTap: () => context.push('/support'),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _aboutSections(Map<String, dynamic> data) {
    final sections = <(String, String)>[];
    void add(String key, String label) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        sections.add((label, value.trim()));
      }
    }

    add('mission_md', 'Our mission');
    add('vision_md', 'Our vision');
    add('who_for_md', 'Who VerifAI is for');
    add('south_africa_md', 'Our commitment to South Africa');
    add('how_it_helps_md', 'How VerifAI helps');
    return sections;
  }
}

// ---------------------------------------------------------------------------
// Help & Support
// ---------------------------------------------------------------------------

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpAsync = ref.watch(supportHelpProvider);
    return VerifaiPageScaffold(
      title: 'Help & Support',
      actions: [
        Consumer(builder: (context, ref, _) {
          final unread = ref.watch(supportUnreadTicketsProvider).valueOrNull ?? 0;
          return IconButton(
            tooltip: 'Your requests',
            onPressed: () => context.push('/support/tickets'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.confirmation_number_outlined),
            ),
          );
        }),
      ],
      body: helpAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SupportError(
          message: 'Could not load help articles.',
          onRetry: () => ref.invalidate(supportHelpProvider),
        ),
        data: (articles) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _SupportHero(
              eyebrow: 'YOUR VERIFAI GUIDE',
              title: 'Learn how to use every part of the platform.',
              subtitle:
                  'A practical guide to getting started, learning, practising, using Vera and reviewing verification results.',
              icon: Icons.support_agent_rounded,
            ),
            const SizedBox(height: 20),
            for (final article in articles)
              _SectionCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  title: Text(article.title,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900)),
                  subtitle: Text(article.summary,
                      style: TextStyle(color: AppColors.textSecondary)),
                  children: [
                    InlineMarkdownText(article.bodyMd,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.55,
                            fontSize: 13.5)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _ActionCard(
              icon: Icons.quiz_rounded,
              title: 'Still have a question?',
              subtitle: 'Browse common questions and quick answers.',
              label: 'Open FAQs',
              onTap: () => context.push('/support/faq'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.mail_outline_rounded,
              title: 'Need personal assistance?',
              subtitle: 'Send a query or report a problem to the team.',
              label: 'Contact support',
              onTap: () => context.push('/support/contact'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact + my tickets
// ---------------------------------------------------------------------------

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'other';
  bool _sending = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialised) return;
      _initialised = true;
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _name.text = user.name ?? '';
        _email.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      showFeedback(context, FeedbackKind.error,
          'Please fill in your name, email, subject and message.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      showFeedback(context, FeedbackKind.error,
          'Please enter a valid email address.');
      return;
    }
    if (subject.length < 3) {
      showFeedback(context, FeedbackKind.error,
          'The subject must be at least 3 characters.');
      return;
    }
    if (message.length < 10) {
      showFeedback(context, FeedbackKind.error,
          'Please add a little more detail (at least 10 characters).');
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await ref.read(apiClientProvider).submitSupportContact(
            name: name,
            email: email,
            category: _category,
            subject: subject,
            message: message,
          );
      if (!mounted) return;
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportUnreadTicketsProvider);
      _subject.clear();
      _message.clear();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Request sent'),
          content: SelectableText(
              'Your reference is ${result.ticketId}. We usually reply within ${result.expectedReply}.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.push('/support/tickets/${result.ticketId}');
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    return VerifaiPageScaffold(
      title: 'Contact Support',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SupportHero(
            eyebrow: 'WE ARE HERE TO HELP',
            title: 'Tell us what you need help with.',
            subtitle:
                'Send a question, technical issue or suggestion. We reply in the app with a ticket reference.',
            icon: Icons.headset_mic_rounded,
          ),
          const SizedBox(height: 20),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send a query',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'bug', child: Text('Bug / technical issue')),
                    DropdownMenuItem(value: 'account', child: Text('Account')),
                    DropdownMenuItem(value: 'content', child: Text('Learning content')),
                    DropdownMenuItem(value: 'verification', child: Text('Verification')),
                    DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'other'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _subject,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: _message,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _BodyText(
                    'Do not include passwords, one-time codes, bank details, identity numbers or confidential third-party information.'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Sending…' : 'Send request'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Your requests',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              TextButton(
                onPressed: () => context.push('/support/tickets'),
                child: const Text('View all'),
              ),
            ],
          ),
          ticketsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const _BodyText('Could not load your requests.'),
            data: (tickets) => tickets.isEmpty
                ? const _BodyText('No requests yet.')
                : Column(
                    children: [
                      for (final ticket in tickets.take(3))
                        _TicketTile(ticket: ticket),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Badge(
          isLabelVisible: ticket.unread,
          child: Icon(
            ticket.status == 'resolved'
                ? Icons.check_circle_outline_rounded
                : Icons.confirmation_number_outlined,
            color: ticket.unread ? AppColors.error : AppColors.accentGreen,
          ),
        ),
        title: Text('${ticket.publicRef} · ${ticket.subject}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${ticket.status.replaceAll('_', ' ')} · ${ticket.replyCount} replies'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () =>
            context.push('/support/tickets/${ticket.publicRef}'),
      ),
    );
  }
}

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    return VerifaiPageScaffold(
      title: 'Your requests',
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SupportError(
          message: 'Could not load your requests.',
          onRetry: () => ref.invalidate(supportTicketsProvider),
        ),
        data: (tickets) => tickets.isEmpty
            ? const Center(child: Text('No requests yet.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(supportTicketsProvider);
                  ref.invalidate(supportUnreadTicketsProvider);
                  await ref.read(supportTicketsProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _TicketTile(ticket: tickets[i]),
                ),
              ),
      ),
    );
  }
}

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ref});
  final String ref;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  Future<SupportTicketDetail>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(apiClientProvider).getMyTicket(widget.ref);
    ref
        .read(apiClientProvider)
        .markMyTicketRead(widget.ref)
        .then((_) {
          ref.invalidate(supportTicketsProvider);
          ref.invalidate(supportUnreadTicketsProvider);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return VerifaiPageScaffold(
      title: widget.ref,
      body: FutureBuilder<SupportTicketDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _SupportError(
              message: 'Could not load this request.',
              onRetry: () => setState(_load),
            );
          }
          final detail = snapshot.data!;
          final t = detail.ticket;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Chip(label: Text(t.publicRef)),
                  Chip(label: Text(t.status.replaceAll('_', ' '))),
                  Chip(label: Text(t.category)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(t.subject,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              _TicketMessage(text: t.message ?? '', fromAdmin: false),
              for (final reply in detail.replies)
                _TicketMessage(
                    text: reply.body, fromAdmin: reply.authorType == 'admin'),
              const SizedBox(height: AppSpacing.md),
              const _BodyText(
                  'This conversation is read-only. The VerifAI team reply is the final response on this request.'),
            ],
          );
        },
      ),
    );
  }
}

class _TicketMessage extends StatelessWidget {
  const _TicketMessage({required this.text, required this.fromAdmin});
  final String text;
  final bool fromAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fromAdmin ? AppColors.accentLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fromAdmin ? 'VerifAI support' : 'You',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: fromAdmin
                      ? AppColors.accentGreen
                      : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ
// ---------------------------------------------------------------------------

class VerifaiFaqScreen extends ConsumerStatefulWidget {
  const VerifaiFaqScreen({super.key});

  @override
  ConsumerState<VerifaiFaqScreen> createState() => _VerifaiFaqScreenState();
}

class _VerifaiFaqScreenState extends ConsumerState<VerifaiFaqScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqsAsync = ref.watch(supportFaqsProvider);
    return VerifaiPageScaffold(
      title: 'Frequently Asked Questions',
      body: faqsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SupportError(
          message: 'Could not load the FAQs.',
          onRetry: () => ref.invalidate(supportFaqsProvider),
        ),
        data: (faqs) {
          final query = _search.text.trim().toLowerCase();
          final visible = query.isEmpty
              ? faqs
              : faqs
                  .where((f) =>
                      f.question.toLowerCase().contains(query) ||
                      f.answerMd.toLowerCase().contains(query) ||
                      f.topic.toLowerCase().contains(query))
                  .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              const _SupportHero(
                eyebrow: 'QUICK ANSWERS',
                title: 'Find your answer.',
                subtitle:
                    'Search common questions about learning, Vera, verification, progress and your account.',
                icon: Icons.quiz_rounded,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search questions…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No matching questions. Try a different search.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final faq in visible)
                  _SectionCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      title: Text(faq.question,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                      subtitle: Text(faq.topic,
                          style: TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      children: [
                        InlineMarkdownText(faq.answerMd,
                            style: TextStyle(
                                height: 1.55,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.mail_outline_rounded,
                title: 'Still not answered?',
                subtitle: 'Send us a query and track the reply in the app.',
                label: 'Contact support',
                onTap: () => context.push('/support/contact'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Industry guide
// ---------------------------------------------------------------------------

class IndustryGuideScreen extends ConsumerWidget {
  const IndustryGuideScreen({super.key, required this.industry});
  final String industry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(supportGuideForIndustryProvider(industry));
    return VerifaiPageScaffold(
      title: '$industry guide',
      body: guideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _SupportError(
          message: 'Could not load this industry guide.',
          onRetry: () =>
              ref.invalidate(supportGuideForIndustryProvider(industry)),
        ),
        data: (guide) => _GuideBody(guide: guide),
      ),
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.guide});
  final SupportGuide guide;

  @override
  Widget build(BuildContext context) {
    final outcomes = guide.outcomes;
    final byTheEnd = (outcomes['by_the_end'] as List<dynamic>?) ?? const [];
    final features = guide.featureTour;
    final howTo = guide.howTo;
    final firstSession = (howTo['first_session'] as List<dynamic>?) ?? const [];
    final mistakes = (howTo['common_mistakes'] as List<dynamic>?) ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryFill, AppColors.greenFill],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR INDUSTRY PATHWAY',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(guide.trackName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(guide.tagline,
                  style: const TextStyle(
                      color: Color(0xFFE1EAE4), height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _Heading('What this industry is about'),
        InlineMarkdownText(guide.overviewMd,
            style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary)),
        if (outcomes['who_for'] is String) ...[
          const SizedBox(height: 16),
          const _Heading('Who it is for'),
          _BodyText(outcomes['who_for'] as String),
        ],
        if (byTheEnd.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _Heading('What you will be able to do'),
          for (final item in byTheEnd) _Bullet('$item'),
        ],
        const SizedBox(height: 22),
        const _Heading('Explore your VerifAI toolkit'),
        for (final tour in features) _FeatureTour(map: _map(tour)),
        if (firstSession.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _Heading('Your first 15 minutes'),
          for (final step in firstSession)
            _SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentLight,
                    child: Text('${_map(step)['step'] ?? ''}',
                        style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_map(step)['title'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        InlineMarkdownText('${_map(step)['body_md'] ?? ''}',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.45,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (mistakes.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _Heading('Common mistakes'),
          for (final mistake in mistakes)
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_map(mistake)['mistake'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${_map(mistake)['how_the_app_helps'] ?? ''}',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.45)),
                ],
              ),
            ),
        ],
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.support_agent_rounded,
          title: 'Questions about this pathway?',
          subtitle: 'Ask the team or browse the FAQs.',
          label: 'Contact support',
          onTap: () => context.push('/support/contact'),
        ),
      ],
    );
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(text,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 16, color: AppColors.accentGreen),
            const SizedBox(width: 8),
            Expanded(child: _BodyText(text, size: 13.5)),
          ],
        ),
      );
}

class _FeatureTour extends StatelessWidget {
  const _FeatureTour({required this.map});
  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final items = (map['items'] as List<dynamic>?) ?? const [];
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${map['title'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          if (map['body_md'] is String) ...[
            const SizedBox(height: 6),
            InlineMarkdownText(map['body_md'] as String,
                style: TextStyle(
                    color: AppColors.textSecondary, height: 1.45)),
          ],
          for (final item in items) ...[
            const SizedBox(height: 8),
            Text('${_map(item)['name'] ?? _map(item)['feature'] ?? ''}',
                style: TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800)),
            if (_map(item)['what_to_check'] is String)
              _BodyText(_map(item)['what_to_check'] as String, size: 13),
            if (_map(item)['body_md'] is String)
              InlineMarkdownText(_map(item)['body_md'] as String,
                  style: TextStyle(
                      color: AppColors.textSecondary, height: 1.45)),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}
