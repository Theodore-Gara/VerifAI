import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/pref_row.dart';
import 'package:verifai/shared/widgets/sample_data_banner.dart';

/// Polished frontend-first product areas. These screens are safe demo surfaces:
/// they do not claim to have verified real documents or submitted real donations.
enum VerifAiHubMode { assistant, verify, lab, practice, rewards, history }

class ProductHubScreen extends ConsumerStatefulWidget {
  const ProductHubScreen({super.key, required this.mode});
  final VerifAiHubMode mode;
  @override
  ConsumerState<ProductHubScreen> createState() => _ProductHubScreenState();
}

class _ProductHubScreenState extends ConsumerState<ProductHubScreen> {
  final _message = TextEditingController();
  final _documentName =
      TextEditingController(text: 'quarterly_financial_report_v2.pdf');
  final _claimController = TextEditingController(
      text:
          '73% of enterprises reduced operating risk using LLM verification gates.');
  final _aiResponseController = TextEditingController(
      text:
          'Based on Section 4.2, the board approved a 15% dividend payout scheduled for Q3 2025.');
  final _sourceController = TextEditingController(
      text:
          'https://sec.gov/edgar/data/0001018724/quarterly-filing-2025-q2.pdf');
  String _industry = 'Software Engineering';
  String _reply = '';
  int _xp = 240;
  int _selected = 0;
  int _practiceSelected = 0;
  bool _showReport = false;

  @override
  void initState() {
    super.initState();
    final trackName = ref.read(currentUserProvider).valueOrNull?.trackName;
    if (trackName != null && trackName.isNotEmpty) {
      _industry = _canonicalIndustry(trackName);
    }
  }

  static String _canonicalIndustry(String trackName) =>
      switch (trackName.toLowerCase()) {
        'legal' => 'Legal',
        'finance' => 'Finance',
        'it / software' => 'Software Engineering',
        'business consulting' => 'Business',
        _ => 'Software Engineering'
      };

  @override
  void dispose() {
    _message.dispose();
    _documentName.dispose();
    _claimController.dispose();
    _aiResponseController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = _details(widget.mode);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          details.title,
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryNavy,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
          child: FeedbackOverlay(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _heroText(details),
              const SizedBox(height: 20),
              if (widget.mode == VerifAiHubMode.assistant) _assistant(),
              if (widget.mode == VerifAiHubMode.verify) _verification(),
              if (widget.mode == VerifAiHubMode.lab) _lab(),
              if (widget.mode == VerifAiHubMode.practice) _practice(),
              if (widget.mode == VerifAiHubMode.rewards) _rewards(),
              if (widget.mode == VerifAiHubMode.history) _history(),
            ]),
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared building blocks (text-led, minimal, on-brand)
  // ---------------------------------------------------------------------------

  Widget _heroText(_HubDetails d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.kicker.toUpperCase(),
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 6),
          Text(d.headline,
              style: const TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(d.subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.45)),
        ],
      );

  Widget _sectionTitle(String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
                letterSpacing: -0.2)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4))
      ]));

  Widget _card({required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3))
          ]),
      child: child);

  Widget _pill(String text, {Color color = AppColors.accentGreen}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
          color: color == AppColors.accentGreen
              ? AppColors.accentLight
              : color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text,
          style: TextStyle(
              color: color == AppColors.warning
                  ? AppColors.goldDark
                  : color == AppColors.accentGreen
                      ? AppColors.accentGreen
                      : AppColors.primaryNavy,
              fontWeight: FontWeight.w800,
              fontSize: 10.5)));

  Widget _xpPill(int amount) => Text(
        '+$amount XP',
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      );

  Widget _button(String text, VoidCallback onPressed) => ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg))),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w700, letterSpacing: 0.2)));

  Widget _chatBubble({required String text, required bool assistant}) => Align(
        alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: assistant ? Colors.white : AppColors.primaryNavy,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(assistant ? 4 : 16),
              bottomRight: Radius.circular(assistant ? 16 : 4),
            ),
            border: assistant ? Border.all(color: AppColors.border) : null,
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Text(text,
              style: TextStyle(
                  color: assistant ? AppColors.primaryNavy : Colors.white,
                  fontSize: 13,
                  height: 1.5)),
        ),
      );

  // ---------------------------------------------------------------------------
  // Assistant mode
  // ---------------------------------------------------------------------------

  void _askAssistant() {
    final prompt = _message.text.trim();
    final lower = prompt.toLowerCase();
    final String response;
    if (prompt.isEmpty) {
      response =
          'Try asking me how to verify a claim, spot a hallucination, assess bias, protect private data, or test AI-generated code.';
    } else if (lower.contains('hallucin') ||
        lower.contains('false') ||
        lower.contains('wrong')) {
      response =
          'Start by isolating the exact claim. Check it against an authoritative, independent source and confirm the source supports the same wording and context. If you cannot confirm it, label it unverified rather than automatically calling it false. What source could you check first?';
    } else if (lower.contains('bias') || lower.contains('fair')) {
      response =
          'Consider who could be affected, whether the data represents those groups, and whether the decision has a disparate impact. Look for measurable evidence, test across relevant groups, and involve a responsible human reviewer. What outcome would you compare to check for unfairness?';
    } else if (lower.contains('privacy') ||
        lower.contains('data') ||
        lower.contains('confidential')) {
      response =
          'Before sharing information with an AI tool, identify whether it contains personal, confidential, or regulated data. Check your organisation’s approved-tool policy and the tool’s data-handling terms. Do not upload sensitive information to an unapproved service.';
    } else if (lower.contains('code') ||
        lower.contains('software') ||
        lower.contains('test')) {
      response =
          'Treat generated code as a proposal, not a guarantee. Read it, check official documentation, inspect security-sensitive paths, and run unit and edge-case tests before accepting it. Which behaviour or failure case would you test first?';
    } else if (lower.contains('govern') ||
        lower.contains('accountab') ||
        lower.contains('risk')) {
      response =
          'Map the use case, affected people, data involved, potential harms, and who is accountable. Then check relevant law, organisational policy, and documented controls. AI output alone is not evidence that a use is compliant.';
    } else {
      response =
          'Let’s work through that together. Identify the exact claim or decision, then look for a reliable primary source and check whether the evidence supports the wording. Consider what might be missing, outdated, biased, or uncertain. What evidence have you found so far?';
    }
    setState(() => _reply = response);
  }

  Widget _assistant() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Your thinking partner',
            'Ask for guidance. Keep the final judgement yours.'),
        _card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VerifAI is here',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 3),
          const Text('Curious, careful, evidence-first.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Bring me a claim, an AI answer, or a tricky idea. I’ll help you reason through it, without making the decision for you.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quick starters',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Give me a hint without revealing the answer',
              'How can I verify this claim?',
              'What risks should I consider?',
            ]
                .map(
                  (prompt) => ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    onPressed: () => setState(() => _message.text = prompt),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppColors.primaryNavy),
            decoration: InputDecoration(
              hintText: 'Ask your question…',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide:
                    const BorderSide(color: AppColors.primaryNavy, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _button('Send to VerifAI', _askAssistant),
        ])),
        if (_reply.isNotEmpty)
          _card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Your conversation',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.primaryNavy)),
                const SizedBox(height: 12),
                _chatBubble(
                    text: _message.text.trim().isEmpty
                        ? 'Can you help me think this through?'
                        : _message.text.trim(),
                    assistant: false),
                _chatBubble(text: _reply, assistant: true),
                const SizedBox(height: 4),
                const SampleDataBanner(
                    message:
                        'Demo guidance only: this chat is not yet connected to the live GPT service.'),
              ])),
      ]);

  // ---------------------------------------------------------------------------
  // Verification Studio mode
  // ---------------------------------------------------------------------------

  Widget _verification() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Choose what to verify',
            'Select an artifact type to configure verification parameters and run evidence checks.'),
        _artifactRows(),
        const SizedBox(height: 14),
        _buildVerificationWorkspace(),
        if (_showReport) ...[
          const SizedBox(height: 14),
          _buildVerificationReport(),
        ],
      ]);

  List<({String title, String desc})> get _artifactItems => [
        (
          title: 'Document',
          desc: 'Audit PDF, doc, or policy text for unsupported assertions',
        ),
        (
          title: 'Claim',
          desc: 'Decompose assertions into checkable factual units',
        ),
        (
          title: 'AI Response',
          desc: 'Inspect model output for hallucinations & bias',
        ),
        (
          title: 'Source',
          desc: 'Verify domain authority, date, and citations',
        ),
      ];

  Widget _artifactRows() {
    final items = _artifactItems;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => setState(() {
                _selected = i;
                _showReport = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: _selected == i
                        ? AppColors.primaryNavy
                        : AppColors.border,
                    width: _selected == i ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.primaryNavy)),
                          const SizedBox(height: 2),
                          Text(items[i].desc,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _selected == i
                            ? AppColors.primaryNavy
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selected == i
                              ? AppColors.primaryNavy
                              : AppColors.border,
                          width: _selected == i ? 2.0 : 1.5,
                        ),
                      ),
                      child: _selected == i
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationWorkspace() {
    final meta = [
      (
        badge: 'DOCUMENT AUDIT',
        title: 'Document Assessment Parameters',
        hint:
            'Review document contents, citation density, and unsupported factual assertions.',
        label: 'Document name or reference',
        controller: _documentName,
        maxLines: 1,
        placeholder: 'e.g. quarterly_financial_report_v2.pdf',
        extraHint:
            'PDF / DOCX document attached (1.4 MB) • 8 pages indexed for audit.',
      ),
      (
        badge: 'CLAIM DECOMPOSITION',
        title: 'Claim Decomposition & Check',
        hint:
            'Isolate verifiable claims and test against authoritative ground truth sources.',
        label: 'Proposition or claim statement',
        controller: _claimController,
        maxLines: 2,
        placeholder:
            'e.g. 73% of enterprises reduced operating risk using LLM verification gates.',
        extraHint:
            'Breakdown: 1 quantitative metric, 1 causal proposition to verify.',
      ),
      (
        badge: 'AI OUTPUT AUDIT',
        title: 'AI Response Review & Bias Scan',
        hint:
            'Inspect generated text for fabricated facts, hallucinations, and confidence gaps.',
        label: 'AI-generated response text',
        controller: _aiResponseController,
        maxLines: 3,
        placeholder: 'Paste the model output to audit…',
        extraHint:
            'Audit scope: hallucination detection, hallucinated references, policy safety.',
      ),
      (
        badge: 'SOURCE CREDIBILITY',
        title: 'Source Authority & Freshness Check',
        hint:
            'Evaluate publisher credibility, publication date, peer-review status, and primary citations.',
        label: 'Source URL, DOI, or publication citation',
        controller: _sourceController,
        maxLines: 2,
        placeholder: 'https://… or journal citation',
        extraHint:
            'Checks: domain reputation, date freshness, author credentials, primary vs secondary.',
      ),
    ][_selected.clamp(0, 3)];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meta.title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta.hint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            meta.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: meta.controller,
            maxLines: meta.maxLines,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryNavy,
            ),
            decoration: InputDecoration(
              hintText: meta.placeholder,
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide:
                    const BorderSide(color: AppColors.primaryNavy, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    meta.extraHint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _button(
            'Preview verification report',
            () => setState(() => _showReport = true),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationReport() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Verification Report Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primaryNavy,
                ),
              ),
              Spacer(),
              _HubNoticePill('HUMAN REVIEW REQUIRED'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _microMetric('Items to Review', '3', AppColors.goldDark),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: _microMetric(
                      'Sources Verified', '1 / 4', AppColors.primaryNavy),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: _microMetric(
                      'Certainty Score', '68%', AppColors.goldDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _reportTelemetryRow(
            'Factual Claims',
            '4 claims extracted • 1 unsupported metric detected',
            AppColors.warning,
          ),
          _reportTelemetryRow(
            'Source Provenance',
            'Primary filing verified • Secondary citation expired',
            AppColors.warning,
          ),
          _reportTelemetryRow(
            'Temporal Freshness',
            'Data timestamped Q2 2023 used for Q3 2025 projection',
            AppColors.info,
          ),
          _reportTelemetryRow(
            'Human-in-the-Loop Gate',
            'Requires domain expert sign-off before downstream usage',
            AppColors.accentGreen,
          ),
          const SizedBox(height: 12),
          const SampleDataBanner(
              message:
                  'Sample report layout. Connect backend verification pipeline to execute live LLM inference & automated checks.'),
        ],
      ),
    );
  }

  Widget _microMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _reportTelemetryRow(String title, String detail, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Lab mode — full-screen lesson pages (no bottom sheet)
  // ---------------------------------------------------------------------------

  Widget _lab() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Small lessons. Real skills.',
            'Learn, try a scenario, then check your understanding.'),
        ..._labLessons.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PrefRow(
                  title: e.value.title,
                  subtitle: e.value.summary,
                  trailing: e.value.duration,
                  trailingSubtle: true,
                  showChevron: true,
                  onTap: () => _openLesson(e.value),
                ),
              ),
            ),
      ]);

  static const _labLessons = <_Lesson>[
    _Lesson(
      title: 'AI fundamentals',
      summary: 'How language models generate answers.',
      body:
          'Language models predict likely next words based on patterns in training data. That is why fluent output can still be wrong: the model optimises for plausibility, not truth. Treat every specific claim in the output as something that needs checking against an independent source.',
      duration: '8 min',
    ),
    _Lesson(
      title: 'Fact-checking with AI',
      summary: 'Trace claims back to trustworthy sources.',
      body:
          'Break the AI output into individual factual claims. For each claim, find an authoritative primary source and confirm it supports the same wording, time period, and context. Label anything you cannot confirm as unverified instead of guessing.',
      duration: '6 min',
    ),
    _Lesson(
      title: 'AI ethics & bias',
      summary: 'Recognise bias, privacy and fairness risks.',
      body:
          'Bias enters through unrepresentative data, proxy variables and historical patterns. Ask who could be harmed, whether groups are represented in the data, and whether a decision has a disparate impact. Never paste personal, confidential, or regulated data into an unapproved AI tool.',
      duration: '7 min',
    ),
    _Lesson(
      title: 'Research & productivity',
      summary: 'Use AI to organise work without outsourcing judgement.',
      body:
          'AI is excellent at summarising, restructuring and drafting — and poor at deciding what is true or important for your context. Use it to accelerate the research grind, then verify key claims and make the judgement calls yourself.',
      duration: '5 min',
    ),
    _Lesson(
      title: 'Engineering & machine learning',
      summary: 'Understand testing, data and model limitations.',
      body:
          'A model’s training data defines what it can and cannot know. Generated code is a proposal: read it, check the official documentation, inspect security-sensitive paths, and run unit and edge-case tests before accepting it.',
      duration: '10 min',
    ),
  ];

  void _openLesson(_Lesson lesson) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _LessonScreen(lesson: lesson),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Practice mode
  // ---------------------------------------------------------------------------

  Widget _practice() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Practice across four industries',
            'Choose a pathway. Each scenario asks you to make a decision and explain why.',
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill('REAL-WORLD SCENARIO • $_industry'),
                const SizedBox(height: 12),
                Text(
                  _scenarioTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _scenarioBody(),
                  style: const TextStyle(
                    height: 1.45,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What is the most responsible next step?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 10),
                ..._options().asMap().entries.map(
                  (e) {
                    final isSelected = _practiceSelected == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _practiceSelected = e.key),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryNavy
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryNavy
                                        : AppColors.border,
                                    width: isSelected ? 2.0 : 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.primaryNavy,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                _button('Check my reasoning', () {
                  final correct = _practiceSelected == 0;
                  if (correct) setState(() => _xp += 20);
                  showFeedback(
                    context,
                    correct ? FeedbackKind.success : FeedbackKind.error,
                    correct
                        ? 'Good judgement — evidence-first. +20 XP (demo).'
                        : 'Not quite. Consider evidence, safety and professional responsibility before acting, then try again.',
                  );
                }),
              ],
            ),
          ),
        ],
      );

  String _scenarioTitle() => switch (_industry) {
        'Legal' => 'An AI cites a case you cannot locate',
        'Finance' => 'An AI summary reports an unusually high return',
        'Software Engineering' =>
          'AI suggests a library method you do not recognise',
        _ => 'AI recommends a market decision using unclear sources'
      };

  String _scenarioBody() => switch (_industry) {
        'Legal' =>
          'A draft legal memo includes a confident case citation. The deadline is close, but you have not confirmed the case exists or whether it supports the argument.',
        'Finance' =>
          'An AI-generated investment summary states a strong expected return but provides no methodology and uses old market data.',
        'Software Engineering' =>
          'An AI-generated code change uses an unfamiliar API and touches authentication logic. Tests have not been run.',
        _ =>
          'An AI-generated market report recommends entering a new region, but its figures have no clear source or date.'
      };

  List<String> _options() => switch (_industry) {
        'Legal' => [
            'Verify the case in an authoritative legal database and check the relevant passage',
            'Trust the citation because the writing sounds professional',
            'Submit now and correct it only if someone notices'
          ],
        'Finance' => [
            'Verify figures, dates, assumptions and source quality before relying on the analysis',
            'Treat the forecast as guaranteed',
            'Share it with clients without further checks'
          ],
        'Software Engineering' => [
            'Check official documentation, review security implications and run appropriate tests',
            'Merge immediately because AI wrote it',
            'Remove the tests to meet the deadline'
          ],
        _ => [
            'Trace key claims to current reliable sources and test assumptions',
            'Use the report without checking its data',
            'Present the recommendation as a certainty'
          ]
      };

  // ---------------------------------------------------------------------------
  // Rewards mode
  // ---------------------------------------------------------------------------

  Widget _rewardTile({
    required String image,
    required String title,
    required String subtitle,
    required String cost,
    required String note,
  }) =>
      PrefRow(
        title: title,
        subtitle: '$subtitle · $note',
        trailing: cost,
      );

  Widget _rewards() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Make your XP mean something',
            'Milestones and reward concepts to celebrate consistent verification practice.'),
        _card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUR LEARNING WALLET',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$_xp XP',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.5)),
            const Spacer(),
            _pill('LEVEL 2 · VERIFICATION EXPLORER'),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 7,
              color: AppColors.border.withValues(alpha: 0.6),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_xp / 300).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Level 3 unlocks at 300 XP',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ])),
        const SizedBox(height: 12),
        _sectionTitle('Choose your feel-good goal',
            'Collect ideas for rewards, play, or giving back.'),
        _rewardTile(
          image: 'reward_coffee',
          title: 'Coffee break',
          subtitle:
              'A coffee reward concept for celebrating a learning streak.',
          cost: '500 XP',
          note: 'Illustrative mock-up',
        ),
        _rewardTile(
          image: 'reward_paws',
          title: 'Paws for a cause',
          subtitle:
              'Support an animal rescue or shelter once a verified partner is available.',
          cost: '800 XP',
          note: 'No donation made',
        ),
        _rewardTile(
          image: 'reward_game',
          title: 'Game night',
          subtitle:
              'A gaming reward concept inspired by cozy sandbox adventures.',
          cost: '650 XP',
          note: 'No game code included',
        ),
        _rewardTile(
          image: 'reward_impact',
          title: 'Community impact',
          subtitle:
              'Support a vetted non-profit organisation, subject to partner approval.',
          cost: '1,000 XP',
          note: 'Partner needed',
        ),
        _rewardTile(
          image: 'reward_grocery',
          title: 'Everyday essentials',
          subtitle:
              'Illustrative voucher concept for a future verified rewards partner.',
          cost: '1,400 XP',
          note: 'Partner required',
        ),
        _rewardTile(
          image: 'reward_fuel',
          title: 'Fuel your next move',
          subtitle: 'A voucher concept for celebrating consistent practice.',
          cost: '1,800 XP',
          note: 'Partner required',
        ),
        _rewardTile(
          image: 'reward_m365',
          title: 'Microsoft 365 boost',
          subtitle:
              'A productivity voucher or subscription concept for future learners.',
          cost: '2,400 XP',
          note: 'Availability varies',
        ),
        _rewardTile(
          image: 'reward_workshop',
          title: 'Workshop pass',
          subtitle: 'A future ticket to an AI, software, or career workshop.',
          cost: '2,000 XP',
          note: 'Workshop partner needed',
        ),
        _rewardTile(
          image: 'reward_gamecredit',
          title: 'Game store credit',
          subtitle:
              'A digital gaming credit concept for reaching a learning milestone.',
          cost: '2,200 XP',
          note: 'No code included',
        ),
        const SizedBox(height: 8),
        _sectionTitle(
            'Milestones unlocked', 'Keep learning to unlock new badges.'),
        ...[
          ('Starter', '100 XP', 'Your first steps count', true),
          ('Verifier', '300 XP', 'Build evidence-first habits', _xp >= 300),
          (
            'Critical Thinker',
            '600 XP',
            'Complete an AI Lab milestone',
            _xp >= 600
          ),
        ].map((r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: r.$4
                      ? AppColors.accentGreen.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: r.$4 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: r.$4 ? AppColors.accentGreen : AppColors.silver,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          Text(r.$3,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary)),
                        ]),
                  ),
                  _xpPill(-1), // placeholder swapped below
                ],
              ),
            )),
        const SampleDataBanner(
            message:
                'Demo notice: XP has no cash value. Rewards, game offers and donations are concepts only. Real redemption requires an approved partner, funding, clear terms and backend validation.'),
      ]);

  // ---------------------------------------------------------------------------
  // History mode
  // ---------------------------------------------------------------------------

  Widget _history() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Your recent practice',
            'A clean history of the work you do and what to improve next.'),
        ...[
          (
            'Source-checking basics',
            'Software Engineering',
            '82%',
            'Passed',
            AppColors.accentGreen
          ),
          (
            'AI-generated report review',
            'Business',
            '55%',
            'Review recommended',
            AppColors.warning
          ),
          (
            'Evidence and confidentiality',
            'Legal',
            '—',
            'In progress',
            AppColors.info
          ),
          (
            'Financial claim analysis',
            'Finance',
            '91%',
            'Passed',
            AppColors.accentGreen
          )
        ].map((h) => _card(
                child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(h.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.primaryNavy)),
                    const SizedBox(height: 3),
                    Text(h.$2,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: h.$5,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          h.$4,
                          style: TextStyle(
                            color: h.$4 == 'Passed'
                                ? AppColors.accentGreen
                                : h.$4 == 'Review recommended'
                                    ? AppColors.goldDark
                                    : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ])),
              Text(h.$3,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.primaryNavy))
            ]))),
        const SampleDataBanner(
            message:
                'Sample history for layout preview. Connect this screen to the real attempt-history endpoint to display a user’s actual records.'),
      ]);
}

/// Full-screen lesson detail — replaces the old modal bottom sheet so lesson
/// tasks get the whole screen and the user's full focus.
class _LessonScreen extends StatefulWidget {
  const _LessonScreen({required this.lesson});

  final _Lesson lesson;

  @override
  State<_LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<_LessonScreen> {
  int _answer = -1;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          lesson.title,
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryNavy,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: FeedbackOverlay(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(
                    'AI LAB • INTERACTIVE LESSON • ${lesson.duration.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGreen,
                        letterSpacing: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                Text(lesson.summary,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 3))
                      ]),
                  child: Text(lesson.body,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: AppColors.primaryNavy)),
                ),
                const SizedBox(height: 20),
                const Text(
                    'Quick check: What should you do before relying on an AI-generated claim?',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primaryNavy,
                        height: 1.4)),
                const SizedBox(height: 12),
                ...[
                  'Check an authoritative source and supporting evidence',
                  'Assume confident wording means it is correct',
                  'Share it immediately',
                ].asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _answer = e.key),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: _answer == e.key
                                    ? AppColors.primaryNavy
                                    : AppColors.border,
                                width: _answer == e.key ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _answer == e.key
                                        ? AppColors.primaryNavy
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _answer == e.key
                                          ? AppColors.primaryNavy
                                          : AppColors.border,
                                      width: _answer == e.key ? 2.0 : 1.5,
                                    ),
                                  ),
                                  child: _answer == e.key
                                      ? const Icon(Icons.check_rounded,
                                          size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(e.value,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.primaryNavy,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _answer == -1
                        ? null
                        : () {
                            final correct = _answer == 0;
                            showFeedback(
                              context,
                              correct
                                  ? FeedbackKind.success
                                  : FeedbackKind.error,
                              correct
                                  ? 'Correct principle! Evidence matters more than confidence. +10 XP (demo).'
                                  : 'Not quite. AI output still needs independent checking before you rely on it.',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primaryNavy.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    child: const Text('Check my answer',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

class _Lesson {
  const _Lesson({
    required this.title,
    required this.summary,
    required this.body,
    required this.duration,
  });

  final String title;
  final String summary;
  final String body;
  final String duration;
}

class _HubNoticePill extends StatelessWidget {
  const _HubNoticePill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: AppColors.goldDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HubDetails {
  const _HubDetails(this.title, this.kicker, this.headline, this.subtitle);

  final String title, kicker, headline, subtitle;
}

_HubDetails _details(VerifAiHubMode m) => switch (m) {
      VerifAiHubMode.assistant => const _HubDetails(
          'AI Assistant',
          'Think clearly with AI',
          'Your AI thinking partner',
          'Explore ideas, challenge assumptions and learn how to verify what matters.',
        ),
      VerifAiHubMode.verify => const _HubDetails(
          'Verification Studio',
          'Evidence before confidence',
          'Make every claim earn your trust',
          'Review documents, claims, AI responses and sources, with uncertainty made visible.',
        ),
      VerifAiHubMode.lab => const _HubDetails(
          'AI Lab',
          'Learn by doing',
          'Build practical AI judgement',
          'Short interactive workshops in responsible AI, machine learning, research and fact-checking.',
        ),
      VerifAiHubMode.practice => const _HubDetails(
          'Industry Practice',
          'Real work. Better judgement.',
          'Practice decisions that matter',
          'Explore realistic scenarios across Legal, Finance, Software Engineering and Business.',
        ),
      VerifAiHubMode.rewards => const _HubDetails(
          'Rewards',
          'Progress with purpose',
          'Every practice session counts',
          'Earn XP, unlock milestones and build skills you can explain, not just collect badges.',
        ),
      VerifAiHubMode.history => const _HubDetails(
          'Task History',
          'Your learning, in context',
          'See how your judgement grows',
          'Review attempts, identify patterns and choose what to practise next.',
        ),
    };
