
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _forest = Color(0xFF102A23);
const _green = Color(0xFF176B4D);
const _gold = Color(0xFFD6B76E);
const _paper = Color(0xFFF7F5EF);

class AboutVerifaiScreen extends StatelessWidget {
  const AboutVerifaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _forest,
        elevation: 0,
        title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          const _HeroPanel(
            eyebrow: 'WELCOME TO VERIFAI',
            title: 'The future of AI needs human intelligence.',
            subtitle: 'A learning and verification experience helping people understand artificial intelligence, question its outputs and use it responsibly in the real world.',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 24),
          const _InfoSection(title: '01. Who we are', body: 'VerifAI is an AI literacy, learning and verification platform designed to help people develop the knowledge, practical skills and confidence to navigate an increasingly AI-enabled world. It brings learning resources, interactive practice, workplace-inspired scenarios, progress tools and an AI learning assistant into one connected experience. Our focus is not simply teaching people how to access AI tools. It is helping them understand what those tools can do, where they can fail and how to make informed decisions when using them.'),
          const _InfoSection(title: '02. Why we exist', body: 'Artificial intelligence is transforming education, business, finance, technology, healthcare, law and many other industries. It is changing how people research, communicate, analyse information and solve problems. Yet the ability to generate an AI response does not automatically mean that the response is accurate, ethical, relevant or safe to use. People need more than access to technology. They need the ability to question information, recognise limitations, examine evidence, identify potential risks and take responsibility for their decisions. VerifAI exists to help develop those abilities through practical, accessible and engaging learning.'),
          const _InfoSection(title: '03. Our mission', body: 'Our mission is to make responsible artificial intelligence education accessible and practical. We aim to equip learners, students, professionals and organisations with the skills to understand AI, critically evaluate AI-generated information, recognise potential errors and apply human judgment when making important decisions. Through structured learning, realistic scenarios and guided feedback, we want to turn AI awareness into practical capability.'),
          const _InfoSection(title: '04. Our vision', body: 'We envision a world in which people from different backgrounds, communities and industries can confidently participate in the AI-powered economy. We want responsible AI literacy to become an essential part of lifelong learning and workplace development. Our ambition is to contribute to a future where technological progress is accompanied by critical thinking, transparency, accountability and meaningful human oversight. We believe the benefits of AI should be accessible to more people, not limited to those who already have advanced technical knowledge.'),
          const _InfoSection(title: '05. The problem we are addressing', body: 'AI-generated content can sound convincing even when it contains inaccurate facts, fabricated references, outdated information or misleading conclusions. People may rely on an answer without checking its source, understanding its context or considering the consequences. In professional environments, these mistakes can affect decisions, customers, organisations and public trust. Traditional learning can explain AI concepts, but learners also need opportunities to practise identifying problems and making decisions. VerifAI is designed to connect knowledge with practical application.'),
          const _InfoSection(title: '06. Who VerifAI is for', body: 'VerifAI is designed for students preparing for an AI-enabled workplace, graduates developing professional skills, employees learning to use AI responsibly, educators exploring AI literacy and individuals who want to become more confident and informed technology users. Industry pathways help make learning more relevant to different professional environments. Whether someone is beginning their AI journey or strengthening existing knowledge, the goal is to provide a structured place to learn, practise and improve.'),
          const _InfoSection(title: '07. How the platform works', body: 'Users begin by selecting an industry pathway that helps shape their learning context. They can explore lessons, practise through scenarios, complete assessments, use Vera for learning support and review their development through progress tools. Each area supports a continuous cycle: understand a concept, apply it, receive feedback, reflect on the result and improve. The exact activities available can depend on the account and features enabled in the current app version.'),
          const _InfoSection(title: '08. Learn: build your knowledge', body: 'The Learn area is where users develop foundational understanding. It brings together learning materials, lessons, recall activities and assessments where available. Users can explore topics at their own pace, revisit concepts and strengthen their understanding before applying what they have learned. The objective is to make AI education approachable while encouraging curiosity, independent thinking and continuous development.'),
          const _InfoSection(title: '09. Practice: turn knowledge into ability', body: 'The Practice area helps users apply concepts to realistic questions and workplace-inspired situations. Activities can explore verification, AI judgment, risk and governance, and interview preparation. Rather than only memorising definitions, users are encouraged to assess situations, consider evidence, identify risks and explain their reasoning. Responsible AI use requires judgment, not just theoretical knowledge.'),
          const _InfoSection(title: '10. Verification Studio: question the output', body: 'Verification Studio provides a dedicated environment for reviewing supported AI-generated content and examining potential issues. Its purpose is to encourage users to look beyond an answer that appears convincing. Users should consider supporting evidence, source quality, context, accuracy and limitations. Verification tools can assist with the review process, but no automated result should be treated as an absolute guarantee that information is true. Human evaluation remains essential.'),
          const _InfoSection(title: '11. Meet Vera: your AI learning companion', body: 'Vera is the AI assistant within the VerifAI experience. She is designed to support learning by helping users explore concepts, ask questions, request explanations and think through unfamiliar topics. Users can ask for examples, simpler explanations or step-by-step guidance. Vera is intended to support the learning journey rather than replace independent thinking. Like other AI systems, her responses may contain mistakes or omissions, so important information should always be checked.'),
          const _InfoSection(title: '12. Progress, achievements and development', body: 'Learning is a journey, and progress tools help users reflect on that journey. The Progress and Profile areas bring together available indicators such as completed activities, experience points, streaks, readiness skills and achievements. These features are intended to encourage consistency, highlight areas for improvement and make learning milestones visible. They are learning indicators rather than formal qualifications or guarantees of professional competence.'),
          const _InfoSection(title: '13. Industry-focused learning', body: 'AI does not affect every industry in exactly the same way. The risks, responsibilities and opportunities can differ between finance, legal services, software development, business consulting and other professional environments. Industry pathways help connect AI learning to relevant scenarios and professional contexts. Users can explore a pathway that reflects their interests and revisit their industry selection when their learning goals change.'),
          const _InfoSection(title: '14. Our commitment to responsible AI', body: 'We believe AI should be used thoughtfully and responsibly. This means recognising that automated systems can make errors, understanding that outputs may reflect limitations in their training data, protecting private information and considering the people affected by AI-assisted decisions. We encourage users to seek reliable evidence, question unsupported claims, recognise uncertainty and apply appropriate human oversight. Technology should strengthen human capability, not remove human responsibility.'),
          const _InfoSection(title: '15. Our values', body: 'Human-centered innovation: people remain at the centre of meaningful technological progress. Critical thinking: users should be encouraged to question, investigate and understand. Responsibility: AI should be used with awareness of its potential impact. Accessibility: learning should be approachable for people with different levels of technical experience. Transparency: limitations should be acknowledged rather than hidden. Continuous improvement: learning and technology must evolve as the world changes.'),
          const _InfoSection(title: '16. Our commitment to South Africa and beyond', body: 'South Africa has an opportunity to participate meaningfully in the global AI economy. Building digital confidence and practical AI literacy can help learners and professionals prepare for changing workplace expectations. People should have opportunities to understand emerging technologies regardless of whether they come from a technical background. VerifAI aims to contribute to that opportunity through practical learning experiences that can grow and adapt over time.'),
          const _InfoSection(title: '17. Looking ahead', body: 'The development of VerifAI is an ongoing journey. As AI technologies, industries and workplace expectations evolve, learning experiences must evolve too. Our ambition is to continue improving the platform, strengthening its educational value, making its user experience more accessible and creating opportunities for people to practise responsible AI use in increasingly relevant contexts. We want VerifAI to be a place where curiosity becomes knowledge, knowledge becomes practical skill and practical skill supports better decisions.'),
          const SizedBox(height: 24),
          const Text('18. Meet the team behind VerifAI', style: TextStyle(color: _forest, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('VerifAI is brought to life by a collaborative team working to make responsible AI learning practical, accessible and meaningful. We believe that building better technology takes different perspectives, shared effort and a commitment to continuous improvement.', style: TextStyle(color: Color(0xFF53645B), height: 1.65, fontSize: 14)),
          const SizedBox(height: 14),
          const _TeamMemberCard(name: 'Lawandle Naledi Mvelase'),
          const SizedBox(height: 10),
          const _TeamMemberCard(name: 'Mpho Mokoena'),
          const SizedBox(height: 10),
          const _TeamMemberCard(name: 'Theodore Nangara'),
          const SizedBox(height: 10),
          const _TeamMemberCard(name: 'Vusani Mludzi'),
          const SizedBox(height: 10),
          const _TeamMemberCard(name: 'Meshaque Kalonji'),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_forest, Color(0xFF1B5942)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.verified_user_rounded, color: _gold, size: 34),
              SizedBox(height: 16),
              Text('OUR GUIDING PRINCIPLE', style: TextStyle(color: _gold, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
              SizedBox(height: 10),
              Text('AI assists. Humans verify.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, height: 1.2)),
              SizedBox(height: 12),
              Text('We believe the future belongs to people who know how to work with technology while retaining the judgment, curiosity and responsibility that make us human.', style: TextStyle(color: Color(0xFFE1EAE4), height: 1.6, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 22),
          const Text('Explore VerifAI', style: TextStyle(color: _forest, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _ActionCard(icon: Icons.menu_book_rounded, title: 'Explore the learning experience', subtitle: 'Discover lessons, learning materials and assessments.', label: 'Go to Learn', onTap: () => context.go('/learn')),
          const SizedBox(height: 12),
          _ActionCard(icon: Icons.support_agent_rounded, title: 'Need assistance?', subtitle: 'Visit our help and customer support centre.', label: 'Get help', onTap: () => context.push('/support')),
          const SizedBox(height: 24),
          const Center(child: Text('VerifAI\nAI assists. Humans verify.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64716A), height: 1.7, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final String name;
  const _TeamMemberCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F1EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: _forest),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: _forest,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _HeroPanel(
            eyebrow: 'YOUR VERIFAI GUIDE',
            title: 'Learn how to use every part of the platform.',
            subtitle:
                'A practical guide to getting started, learning, practising, using Vera and reviewing verification results.',
            icon: Icons.support_agent_rounded,
          ),
          const SizedBox(height: 20),
          const _HelpChapter(
            number: '01',
            title: 'Getting started',
            body:
                'Sign in or create your account, then follow the industry selection steps. Choose the pathway that best matches your interests or work context. If you are unsure, read the industry guide before selecting. You can revisit help resources later; skipping an introductory tutorial should not prevent you from using this Help & Support area.',
            bullets: [
              'Choose an industry pathway that is relevant to you.',
              'Read the on-screen instructions before continuing.',
              'Use the menu to find help and other destinations.',
            ],
          ),
          const _HelpChapter(
            number: '02',
            title: 'Understanding the dashboard',
            body:
                'The dashboard is your starting point. It brings together shortcuts and a snapshot of your learning activity. The exact cards shown can depend on the features available to your account and selected industry. Open a card to explore the relevant activity, and use the bottom navigation to move between Home, Learn, Practice, Progress and Profile.',
            bullets: [
              'Home returns you to the main dashboard.',
              'Learn gathers lessons and learning materials.',
              'Practice gathers activities that help you apply concepts.',
              'Progress helps you review your learning activity.',
            ],
          ),
          const _HelpChapter(
            number: '03',
            title: 'Learn',
            body:
                'Use Learn to study concepts and build foundational knowledge. Open a lesson or topic, read the material carefully and complete any associated learning activity. Take notes on unfamiliar terms and return to topics when you need to revise. Learning content is intended to build understanding; it is not a substitute for professional advice in regulated fields.',
            bullets: [
              'Start with the recommended lesson or topic.',
              'Read the full explanation and any sources provided.',
              'Use the back arrow to return to the previous area or dashboard.',
            ],
          ),
          const _HelpChapter(
            number: '04',
            title: 'Practice',
            body:
                'Practice is where you apply what you have learned to questions, tasks and workplace-style scenarios. Read the full prompt, consider the context, make a decision and review the feedback. Treat feedback as a learning aid: revisit the underlying lesson if you are unsure why an answer was marked a particular way.',
            bullets: [
              'Read instructions before starting an activity.',
              'Consider evidence and context before choosing an answer.',
              'Review feedback and use it to guide your next study session.',
            ],
          ),
          const _HelpChapter(
            number: '05',
            title: 'Vera AI assistant',
            body:
                'Vera is an AI assistant intended to help explain concepts, support study and help you think through questions. Give clear context and ask focused questions. You can ask for a simpler explanation, examples or a step-by-step breakdown. AI responses can be wrong or incomplete, so independently check important claims and do not share passwords, private records or other sensitive information.',
            bullets: [
              'Ask one clear question at a time.',
              'Request sources or ask what is uncertain.',
              'Check important information before using or sharing it.',
            ],
          ),
          const _HelpChapter(
            number: '06',
            title: 'Verification Studio',
            body:
                'Verification Studio is the area for submitting supported content for checks. Depending on the available workflow, this may include text, documents, links or citations. Follow the accepted input guidance shown in the screen. Review the result, evidence and limitations carefully. A failed check does not automatically prove content is false, and a successful check does not guarantee that every statement is true.',
            bullets: [
              'Use supported file types and follow upload guidance.',
              'Check that pasted text or links are complete.',
              'Review citations and evidence rather than relying only on a status label.',
              'If a check fails, note the error and report it through support.',
            ],
          ),
          const _HelpChapter(
            number: '07',
            title: 'Progress and readiness',
            body:
                'Progress helps you reflect on your activity and development. Scores and readiness indicators should be interpreted as learning signals based on the platform’s available activities, not as a formal qualification, employment guarantee or complete measure of ability. Use the areas highlighted for improvement to plan what to learn or practise next.',
            bullets: [
              'Review completed activities and recent learning.',
              'Look for skills or topics that need more practice.',
              'Use progress as guidance, not as a final judgment of your ability.',
            ],
          ),
          const _HelpChapter(
            number: '08',
            title: 'Rewards and achievements',
            body:
                'Where enabled, rewards such as XP, streaks, achievements or tokens are designed to encourage consistent learning. They recognize activity within the platform; they are not cash, formal credentials or proof of professional competence unless a specific feature explicitly says otherwise.',
            bullets: [
              'Check the reward description to understand its criteria.',
              'Keep a sustainable learning routine.',
              'Focus on understanding, not only collecting points.',
            ],
          ),
          const _HelpChapter(
            number: '09',
            title: 'Changing your industry',
            body:
                'If your interests change or you selected the wrong pathway, use the Change Industry option in the app menu or profile area where available. Select the new pathway and allow the app to refresh industry-specific material. Some learning views and recommendations may change when the selected pathway changes.',
            bullets: [
              'Open the app menu or profile.',
              'Choose Change Industry.',
              'Select the pathway that best matches your needs.',
            ],
          ),
          const _HelpChapter(
            number: '10',
            title: 'Account safety and privacy',
            body:
                'Keep your sign-in details private and sign out when using a shared device. Do not upload information unless you have the right to share it and understand how it will be used. Avoid submitting passwords, payment details, identity documents or confidential workplace information unless the product explicitly supports that use and provides appropriate safeguards.',
            bullets: [
              'Never share your password or verification codes.',
              'Avoid uploading confidential or sensitive material.',
              'Log out on devices that other people can access.',
            ],
          ),
          const _HelpChapter(
            number: '11',
            title: 'Troubleshooting',
            body:
                'If a screen does not load, check your internet connection and try again. If an upload or verification fails, confirm that the file type and size are supported and that the content is accessible. If the issue continues, report what you were doing, what you expected and the exact error message. Do not repeatedly submit sensitive content while troubleshooting.',
            bullets: [
              'Check your connection and retry once.',
              'Update the app if a newer version is available.',
              'Record the screen, action and error message.',
              'Use Contact Support to report a persistent issue.',
            ],
          ),
          const SizedBox(height: 16),
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
            subtitle: 'Send feedback or report a problem to the team.',
            label: 'Contact support',
            onTap: () => context.push('/support/contact'),
          ),
        ],
      ),
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        title: const Text('Contact Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _HeroPanel(
            eyebrow: 'WE ARE HERE TO HELP',
            title: 'Tell us what you need help with.',
            subtitle:
                'Use the feedback and reporting flow to describe a question, technical issue or suggestion.',
            icon: Icons.headset_mic_rounded,
          ),
          const SizedBox(height: 20),
          const _InfoSection(
            title: 'What to include in a support request',
            body:
                'Describe the screen you were using, the action you took, what you expected to happen and what happened instead. Include the exact error message if one appeared. If the issue involves a document or verification, describe the file type and general kind of content without sharing confidential information.',
          ),
          const _InfoSection(
            title: 'Before you submit',
            body:
                'Please do not include passwords, one-time codes, bank details, identity numbers or confidential third-party information. Only attach material you have permission to share. Support requests should contain enough detail to reproduce the issue without exposing private information.',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => context.push('/feedback'),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Open feedback and issue reporting'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Official support email and response hours can be added here once the VerifAI team confirms the correct contact details. We have intentionally not displayed an unverified email address.',
            style: TextStyle(
              color: Color(0xFF64716A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class VerifaiFaqScreen extends StatefulWidget {
  const VerifaiFaqScreen({super.key});

  @override
  State<VerifaiFaqScreen> createState() => _VerifaiFaqScreenState();
}

class _VerifaiFaqScreenState extends State<VerifaiFaqScreen> {
  final _search = TextEditingController();
  String _category = 'All';

  static const _faqs = <_FaqItem>[
    _FaqItem(
      'Getting started',
      'What is VerifAI?',
      'VerifAI is an AI learning and verification platform designed to help people build practical AI literacy, practise workplace judgment and review AI-assisted content more thoughtfully.',
    ),
    _FaqItem(
      'Getting started',
      'How do I choose my industry?',
      'Use the Choose Your Industry screen to select the pathway most relevant to your interests. Read the Learn More guide on a card before selecting if you need more context.',
    ),
    _FaqItem(
      'Getting started',
      'Can I change my industry later?',
      'Yes. Use Change Industry from the app menu or profile area where available, then select another pathway. The learning content and recommendations may refresh for the new industry.',
    ),
    _FaqItem(
      'Getting started',
      'What if I skip the onboarding tutorial?',
      'You can still use the app and return to Help & Support whenever you need guidance. If the app provides a Replay Tutorial option in your account or onboarding screen, use it to revisit the introduction. Skipping the tutorial should not be treated as deleting your account or learning progress.',
    ),
    _FaqItem(
      'Learning',
      'What is the Learn section for?',
      'Learn brings together lessons and learning materials. Use it to understand concepts before applying them in practice activities.',
    ),
    _FaqItem(
      'Learning',
      'What is Practice for?',
      'Practice lets you apply concepts through questions, challenges and scenarios. Review the feedback to understand what to improve.',
    ),
    _FaqItem(
      'Learning',
      'Can I revisit lessons?',
      'You can reopen available learning materials from the Learn area and review them again. Availability may depend on the content provided for your pathway.',
    ),
    _FaqItem(
      'Vera AI',
      'What is Vera?',
      'Vera is the platform’s AI assistant. It can help explain concepts and support learning, but its responses may be inaccurate or incomplete. Check important information independently.',
    ),
    _FaqItem(
      'Vera AI',
      'Can I rely on everything Vera says?',
      'No. AI systems can make mistakes, omit context or produce unsupported claims. Treat Vera as an assistant, verify important information and use human judgment.',
    ),
    _FaqItem(
      'Verification',
      'What is Verification Studio?',
      'Verification Studio is the area for submitting supported content for checks and reviewing the results, evidence and limitations provided by the platform.',
    ),
    _FaqItem(
      'Verification',
      'Does a successful verification mean content is definitely true?',
      'No. A successful result is not a guarantee that every claim is true, complete or current. Read the evidence and limitations and independently check consequential information.',
    ),
    _FaqItem(
      'Verification',
      'Why might my verification fail?',
      'Possible causes include unsupported file formats, inaccessible links, incomplete input, upload problems, network issues or a service error. Check the on-screen message and report persistent problems.',
    ),
    _FaqItem(
      'Verification',
      'Can I verify citations?',
      'Use the citation or reference workflow when it is available in your version of Verification Studio. Review whether sources are accessible and actually support the statements they are attached to.',
    ),
    _FaqItem(
      'Progress & rewards',
      'What does my readiness score mean?',
      'It is a learning indicator based on the activities and information available to the platform. It should not be treated as a formal qualification or a complete measure of professional ability.',
    ),
    _FaqItem(
      'Progress & rewards',
      'What are XP and streaks?',
      'Where enabled, XP and streaks recognize learning activity and consistency within the app. They are motivational indicators, not formal credentials.',
    ),
    _FaqItem(
      'Account',
      'How do I log out?',
      'Open the navigation menu and choose Log out. Confirm the action when prompted.',
    ),
    _FaqItem(
      'Account',
      'How do I get help with a technical problem?',
      'Open Help & Support, choose Contact Support and use the feedback or issue-reporting flow. Include the steps to reproduce the issue and the error message, but do not include sensitive information.',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();

    final visible = _faqs.where((faq) {
      final categoryMatch =
          _category == 'All' || faq.category == _category;

      final queryMatch = query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);

      return categoryMatch && queryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        title: const Text('Frequently Asked Questions'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const _HeroPanel(
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
            decoration: InputDecoration(
              hintText: 'Search questions...',
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
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in const [
                  'All',
                  'Getting started',
                  'Learning',
                  'Vera AI',
                  'Verification',
                  'Progress & rewards',
                  'Account',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) =>
                          setState(() => _category = category),
                      selectedColor: const Color(0xFFDCEAE0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: visible.isEmpty
                ? const Padding(
                    key: ValueKey('faq-empty'),
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No matching questions. Try another search or category.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    key: ValueKey('faq-${_category}_$query'),
                    children: visible
                        .map(
                          (faq) => Card(
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFFE7EAE3),
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 3,
                              ),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              title: Text(
                                faq.question,
                                style: const TextStyle(
                                  color: _forest,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                faq.category,
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              children: [
                                Text(
                                  faq.answer,
                                  style: const TextStyle(
                                    height: 1.55,
                                    color: Color(0xFF53625A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  const _FaqItem(this.category, this.question, this.answer);
}

class _HeroPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroPanel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_forest, Color(0xFF1B5942)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _forest.withValues(alpha: .12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
                  color: _gold,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _forest, size: 25),
              ),
              const SizedBox(width: 12),
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFE1EAE4),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _forest,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF53625A),
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
}

class _HelpChapter extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final List<String> bullets;

  const _HelpChapter({
    required this.number,
    required this.title,
    required this.body,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EAE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _forest,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF53625A),
                height: 1.55,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 10),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: _green,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Color(0xFF53625A),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EFE9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64716A),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _green,
                ),
              ],
            ),
          ),
        ),
      );
}
