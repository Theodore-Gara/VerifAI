import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class IndustryGuideScreen extends StatelessWidget {
  const IndustryGuideScreen({super.key, required this.industry});
  final String industry;

  static const _driveWalkthrough = 'https://drive.google.com/file/d/1ytfv2GYsXvcV5FOYtnQUJliTTIzqQNe3/view?usp=drivesdk';

  _GuideData get _data {
    final key = industry.toLowerCase().replaceAll(' ', '').replaceAll('/', '');
    if (key.contains('finance')) return const _GuideData(name: 'Finance', tagline: 'Build confidence working with financial information, reports and AI-supported decisions.', about: 'Finance is the work of managing, analyzing and making decisions about money, budgets, investments and financial performance.', outcomes: 'Understand financial data, check calculations and sources, and communicate findings responsibly.', icon: Icons.account_balance_rounded, image: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=1200');
    if (key.contains('legal')) return const _GuideData(name: 'Legal', tagline: 'Explore how AI can support careful legal research, document review and evidence checking.', about: 'The legal industry works with laws, regulations, contracts, case information and the rights and responsibilities of people and organizations.', outcomes: 'Learn to examine clauses, trace citations and identify information that needs human legal review.', icon: Icons.gavel_rounded, image: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200');
    if (key.contains('it') || key.contains('software')) return const _GuideData(name: 'IT / Software', tagline: 'Develop practical skills for evaluating AI-assisted technical work and software information.', about: 'IT and software teams build, maintain and secure digital systems, applications, networks and data-driven services.', outcomes: 'Practice reviewing code, checking technical claims, validating sources and explaining risks.', icon: Icons.code_rounded, image: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200');
    return const _GuideData(name: 'Business Consulting', tagline: 'Learn to assess business information and use AI thoughtfully when exploring strategy and operations.', about: 'Business consulting helps organizations understand challenges, improve operations and make informed decisions about strategy, people and performance.', outcomes: 'Practice evaluating recommendations, checking evidence and communicating responsible business decisions.', icon: Icons.business_center_rounded, image: 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200');
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5EF), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop(), tooltip: 'Back to industry selection'),
        title: Text('${d.name} guide', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(alignment: Alignment.bottomLeft, children: [
          Image.network(d.image, height: 220, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 220, color: const Color(0xFF102A23), child: const Icon(Icons.work_outline, color: Colors.white, size: 64))),
          Container(height: 220, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD071A14)]))),
          Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR INDUSTRY PATHWAY', style: TextStyle(color: Color(0xFFE4D09B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 8), Text(d.name, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5), Text(d.tagline, style: const TextStyle(color: Colors.white, height: 1.4)),
          ])),
        ])),
        const SizedBox(height: 24),
        const _SectionTitle('What this industry is about'),
        Text(d.about, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF53625A))),
        const SizedBox(height: 22),
        const _SectionTitle('Explore your VerifAI toolkit'),
        const Text('Your pathway uses the same core tools. Here is what each one does and how to get started.', style: TextStyle(height: 1.5, color: Color(0xFF64716A))),
        const SizedBox(height: 12),
        const _FeatureTile(icon: Icons.menu_book_rounded, title: 'Learn', detail: 'Open learning materials and work through topics at your own pace. Start with a lesson, review the key ideas and complete the learning activities.'),
        const _FeatureTile(icon: Icons.fitness_center_rounded, title: 'Practice', detail: 'Apply what you have learned through industry-related scenarios and tasks. Read the prompt carefully, make your decision and review the feedback.'),
        const _FeatureTile(icon: Icons.auto_awesome_rounded, title: 'Vera AI assistant', detail: 'Ask Vera questions, request explanations and get help understanding concepts. Treat AI responses as assistance: check important claims and use your own judgment.'),
        const _FeatureTile(icon: Icons.fact_check_rounded, title: 'Verification Studio', detail: 'Submit supported text or documents for checks. Review the evidence and any limitations shown in the result; a result is not a guarantee that content is true.'),
        const _FeatureTile(icon: Icons.insights_rounded, title: 'Progress', detail: 'Review your learning activity, readiness indicators and completed work. Use the insights to decide what to practice next.'),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFE8EFE9), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What you will work toward', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF102A23), fontSize: 17)),
          const SizedBox(height: 8), Text(d.outcomes, style: const TextStyle(height: 1.55, color: Color(0xFF42554A))),
          const SizedBox(height: 12), const Text('Remember: AI assists. Humans verify.', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF176B4D))),
        ])),
        const SizedBox(height: 22),
        const _SectionTitle('Watch the walkthrough'),
        const Text('Follow the walkthrough to see how to move through VerifAI and use its main features step by step.', style: TextStyle(height: 1.5, color: Color(0xFF64716A))),
        const SizedBox(height: 12),
        InkWell(onTap: () async { final uri = Uri.parse(_driveWalkthrough); await launchUrl(uri, mode: LaunchMode.externalApplication); }, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF102A23), borderRadius: BorderRadius.circular(18)), child: const Row(children: [
          CircleAvatar(backgroundColor: Color(0xFFD6B76E), child: Icon(Icons.play_arrow_rounded, color: Color(0xFF102A23), size: 28)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Open VerifAI video guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Step-by-step walkthrough • Google Drive', style: TextStyle(color: Color(0xFFD7E1DA), fontSize: 12))])), Icon(Icons.open_in_new_rounded, color: Colors.white),
        ]))),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Back to Choose Your Industry'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF176B4D), side: const BorderSide(color: Color(0xFF176B4D)), padding: const EdgeInsets.symmetric(vertical: 15))),
      ]),
    );
  }
}

class _GuideData {
  final String name, tagline, about, outcomes, image;
  final IconData icon;
  const _GuideData({required this.name, required this.tagline, required this.about, required this.outcomes, required this.icon, required this.image});
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF102A23))));
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.detail});
  final IconData icon; final String title, detail;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE5E8DF))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE8EFE9), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF176B4D))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF102A23))), const SizedBox(height: 5), Text(detail, style: const TextStyle(height: 1.45, color: Color(0xFF64716A), fontSize: 13))]))]));
}
