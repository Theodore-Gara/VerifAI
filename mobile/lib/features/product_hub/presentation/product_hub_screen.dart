import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/core/theme/app_colors.dart';

/// Polished frontend-first product areas. These screens are safe demo surfaces:
/// they do not claim to have verified real documents or submitted real donations.
enum VerifAiHubMode { assistant, verify, lab, practice, rewards, history }

class ProductHubScreen extends StatefulWidget {
  const ProductHubScreen({super.key, required this.mode});
  final VerifAiHubMode mode;
  @override
  State<ProductHubScreen> createState() => _ProductHubScreenState();
}

class _ProductHubScreenState extends State<ProductHubScreen> {
  final _message = TextEditingController();
  final _documentName = TextEditingController();
  String _industry = 'Software Engineering';
  String _reply = '';
  int _xp = 240;
  int _selected = -1;
  bool _showReport = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    if (widget.mode == VerifAiHubMode.lab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakLabWelcome());
    }
  }

  Future<void> _speakLabWelcome() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final alreadyWelcomed =
          preferences.getBool('verifai_ai_lab_voice_welcomed_v1') ?? false;
      if (alreadyWelcomed || !mounted) return;
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(
        'Welcome to the VerifAI A I Lab. Explore the lesson, ask the Lab Coach for help, and remember: AI assists. Humans verify.',
      );
      await preferences.setBool('verifai_ai_lab_voice_welcomed_v1', true);
    } catch (_) {
      // The written lesson content remains available if device speech is unavailable.
    }
  }

  Future<void> _replayLabWelcome() async {
    try {
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.48);
      await _tts.speak(
        'Welcome to the VerifAI A I Lab. Explore the lesson, ask the Lab Coach for help, and remember: AI assists. Humans verify.',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech is unavailable on this device.')),
        );
      }
    }
  }

  Future<void> _replayAssistantWelcome() async {
    try {
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1);
      await _tts.speak(
        'Hi there, welcome to VerifAI. Bring me a claim, an AI answer, or a tricky idea. I will help you reason through it. AI assists. Humans verify.',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech is unavailable on this device.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _documentName.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = _details(widget.mode);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, surfaceTintColor: Colors.transparent,
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accentGreen, AppColors.accentCyan]), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.verified_rounded, color: AppColors.primaryNavy, size: 21)),
          const SizedBox(width: 10), Expanded(child: Text(details.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryNavy))),
        ]),
      ),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        _hero(details), const SizedBox(height: 22),
        if (widget.mode == VerifAiHubMode.assistant) _assistant(),
        if (widget.mode == VerifAiHubMode.verify) _verification(),
        if (widget.mode == VerifAiHubMode.lab) ...[_lab(), const SizedBox(height: 2), _labCoach()],
        if (widget.mode == VerifAiHubMode.practice) _practice(),
        if (widget.mode == VerifAiHubMode.rewards) _rewards(),
        if (widget.mode == VerifAiHubMode.history) _history(),
      ])),
    );
  }

  Widget _hero(_HubDetails d) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryNavy, Color(0xFF123A43)]), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: AppColors.primaryNavy.withValues(alpha: .15), blurRadius: 24, offset: const Offset(0, 10))]),
    child: Stack(children: [
      Positioned(right: -15, top: -20, child: Icon(d.icon, size: 130, color: Colors.white.withValues(alpha: .055))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: .16), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.accentGreen.withValues(alpha: .35))), child: Text(d.kicker.toUpperCase(), style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
        const SizedBox(height: 15), Text(d.headline, style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.5)),
        const SizedBox(height: 9), Text(d.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13, height: 1.5)),
      ]),
    ]),
  );

  Widget _sectionTitle(String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryNavy)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4))]));
  Widget _card({required Widget child}) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: AppColors.primaryNavy.withValues(alpha: .035), blurRadius: 16, offset: const Offset(0, 5))]), child: child);
  Widget _pill(String text, {Color color = AppColors.accentGreen}) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(color: color == AppColors.warning ? AppColors.goldDark : AppColors.primaryNavy, fontWeight: FontWeight.w800, fontSize: 11)));
  Widget _button(String text, VoidCallback onPressed, {IconData icon = Icons.arrow_forward_rounded}) => SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(text), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))));

  Widget _chatBubble({required String text, required bool assistant}) => Align(
    alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 310),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: assistant ? Colors.white : AppColors.primaryNavy,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(assistant ? 5 : 18),
          bottomRight: Radius.circular(assistant ? 18 : 5),
        ),
        border: assistant ? Border.all(color: AppColors.border) : null,
        boxShadow: [BoxShadow(color: AppColors.primaryNavy.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(text, style: TextStyle(color: assistant ? AppColors.primaryNavy : Colors.white, fontSize: 13, height: 1.5)),
    ),
  );

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

  Widget _assistant() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle('Your thinking partner', 'Ask for guidance. Keep the final judgement yours.'),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accentGreen, AppColors.accentCyan]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.auto_awesome_rounded, size: 27, color: AppColors.primaryNavy)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('VerifAI is here ✨', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text('Curious, careful, evidence-first.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]))]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF8), Color(0xFFE8F7FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentGreen.withValues(alpha: .2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Hey! 👋 Bring me a claim, an AI answer, or a tricky idea. I’ll help you reason through it—without making the decision for you.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            IconButton(
              tooltip: 'Listen to welcome',
              onPressed: _replayAssistantWelcome,
              icon: const Icon(Icons.volume_up_rounded,
                  color: AppColors.primaryNavy),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15), const Text('Choose your industry', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: _industry, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), items: const ['Legal','Finance','Software Engineering','Business'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>_industry=v ?? _industry)),
      const SizedBox(height: 15), const Text('Quick starters', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 9),
      Wrap(spacing: 7, runSpacing: 7, children: [
        ('💡 Give me a hint','Give me a hint without revealing the answer'), ('🔎 Verify a claim','How can I verify this claim?'), ('🛡️ Spot risks','What risks should I consider?'),
      ].map((item)=>ActionChip(label: Text(item.$1), onPressed: ()=>setState(()=>_message.text=item.$2), backgroundColor: Colors.white, side: const BorderSide(color: AppColors.border))).toList()),
      const SizedBox(height: 14), TextField(controller:_message, maxLines:2, decoration: InputDecoration(hintText:'Ask your question…', filled:true, fillColor:AppColors.background, border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none), prefixIcon: const Icon(Icons.chat_bubble_outline_rounded))),
      const SizedBox(height: 10), _button('Send to VerifAI', _askAssistant, icon:Icons.send_rounded),
    ])),
    if (_reply.isNotEmpty) _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.auto_awesome_rounded,color:AppColors.accentGreen), SizedBox(width:8), Text('Your conversation',style:TextStyle(fontWeight:FontWeight.w900))]), const SizedBox(height:12),
      _chatBubble(text:_message.text.trim().isEmpty ? 'Can you help me think this through?' : _message.text.trim(), assistant:false),
      _chatBubble(text:_reply, assistant:true),
      const Row(children:[Icon(Icons.info_outline_rounded,size:15,color:AppColors.textSecondary),SizedBox(width:6),Expanded(child:Text('Demo guidance only — this chat is not yet connected to the live GPT service.',style:TextStyle(fontSize:11,color:AppColors.textSecondary)))]),
    ])),
  ]);

  Widget _verification() => Column(crossAxisAlignment:CrossAxisAlignment.start, children:[_sectionTitle('Choose what to verify','A clear report should show evidence, uncertainty and what needs a human check.'), ...[
    ('Document','Review a PDF or report for statements that need checking.',Icons.picture_as_pdf_rounded),('Claim','Break a claim into verifiable parts and identify evidence needed.',Icons.fact_check_rounded),('AI response','Inspect an AI answer for unsupported claims, gaps and risky advice.',Icons.psychology_alt_rounded),('Source','Assess source authority, date, context and relevance.',Icons.travel_explore_rounded)
  ].map((v)=>_card(child:ListTile(contentPadding:EdgeInsets.zero,leading:Container(width:46,height:46,decoration:BoxDecoration(color:AppColors.accentGreen.withValues(alpha:.12),borderRadius:BorderRadius.circular(14)),child:Icon(v.$3,color:AppColors.primaryNavy)),title:Text(v.$1,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Text(v.$2,style:const TextStyle(fontSize:12,height:1.4))),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>setState(()=>_selected=v.$1=='Document'?0:v.$1=='Claim'?1:v.$1=='AI response'?2:3)))),
    if (_selected >= 0) _card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(['Document assessment','Claim check','AI response review','Source assessment'][_selected],style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),const SizedBox(height:8),if(_selected==0) TextField(controller:_documentName,decoration:const InputDecoration(labelText:'Document name',hintText:'e.g. quarterly-report.pdf',border:OutlineInputBorder())),const SizedBox(height:8),const Text('Frontend demo: analysis must be connected to the verification backend before results can be trusted.',style:TextStyle(height:1.45,color:AppColors.textSecondary,fontSize:12)),const SizedBox(height:12),_button('Preview report format',()=>setState(()=>_showReport=true),icon:Icons.description_rounded)])),
    if (_showReport) _card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.assignment_turned_in_rounded,color:AppColors.accentGreen),SizedBox(width:8),Text('Verification report preview',style:TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:12),_reportLine('Items requiring review','3',AppColors.warning),_reportLine('Sources independently confirmed','Not yet checked',AppColors.info),_reportLine('Overall status','Human review required',AppColors.warning),const SizedBox(height:8),const Text('No document has been analysed. This is a sample report layout, not a real assessment.',style:TextStyle(fontSize:11,color:AppColors.textSecondary))]))
  ]);
  Widget _reportLine(String a,String b,Color c)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(a,style:const TextStyle(fontSize:12))),Text(b,style:TextStyle(fontWeight:FontWeight.w800,color:c,fontSize:12))]));

  Widget _lab() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_sectionTitle('Small lessons. Real skills.','Learn, try a scenario, then check your understanding.'), ...[
    ('AI fundamentals','How language models generate answers.','8 min',Icons.memory_rounded),('Fact-checking with AI','Trace claims back to trustworthy sources.','6 min',Icons.manage_search_rounded),('AI ethics & bias','Recognise bias, privacy and fairness risks.','7 min',Icons.balance_rounded),('Research & productivity','Use AI to organise work without outsourcing judgement.','5 min',Icons.bolt_rounded),('Engineering & machine learning','Understand testing, data and model limitations.','10 min',Icons.code_rounded)
  ].map((l)=>_card(child:Column(children:[Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:AppColors.accentGreen.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(l.$4,color:AppColors.primaryNavy)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l.$1,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(l.$2,style:const TextStyle(fontSize:12,color:AppColors.textSecondary,height:1.35))])),_pill(l.$3,color:AppColors.accentGreen)]),const SizedBox(height:14),_button('Start mini-workshop',()=>_showLesson(l.$1,l.$2),icon:Icons.play_arrow_rounded)]))),
  ]);
  Widget _labCoach() => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children:[Container(width:46,height:46,decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.accentGreen,AppColors.accentCyan]),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.forum_rounded,color:AppColors.primaryNavy,size:25)),const SizedBox(width:11),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ask the Lab Coach',style:TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text('Your workshop sidekick',style:TextStyle(color:AppColors.textSecondary,fontSize:12))])),IconButton(tooltip:'Replay AI welcome',onPressed:_replayLabWelcome,icon:const Icon(Icons.volume_up_rounded,color:AppColors.primaryNavy))]),
    const SizedBox(height:12), _chatBubble(text:'Stuck on a concept? 🧠 Ask me to explain it simply, give you a hint, or help you check your reasoning.', assistant:true),
    TextField(controller:_message,maxLines:2,decoration:InputDecoration(hintText:'Ask about this lesson…',filled:true,fillColor:AppColors.background,border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none))),
    const SizedBox(height:10), _button('Ask the Lab Coach',_askAssistant,icon:Icons.auto_awesome_rounded),
    if(_reply.isNotEmpty) ...[const SizedBox(height:12),if(_message.text.trim().isNotEmpty)_chatBubble(text:_message.text.trim(),assistant:false),_chatBubble(text:_reply,assistant:true),const Text('Workshop assistant preview: these guided replies are local demo responses. Live GPT conversations require the secure backend integration.',style:TextStyle(fontSize:11,color:AppColors.textSecondary,height:1.4))],
  ]));

  void _showLesson(String title,String description)=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>Container(padding:const EdgeInsets.fromLTRB(22,22,22,32),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:42,height:4,decoration:BoxDecoration(color:AppColors.border,borderRadius:BorderRadius.circular(4))),const SizedBox(height:20),_pill('AI LAB • INTERACTIVE LESSON'),const SizedBox(height:12),Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:AppColors.primaryNavy)),const SizedBox(height:10),Text(description,style:const TextStyle(height:1.5)),const SizedBox(height:14),const Text('Quick check: What should you do before relying on an AI-generated claim?',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),...['Check an authoritative source and supporting evidence','Assume confident wording means it is correct','Share it immediately'].map((a)=>Padding(padding:const EdgeInsets.only(bottom:7),child:OutlinedButton(onPressed:(){Navigator.pop(ctx);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(a.startsWith('Check')?'Correct principle! Evidence matters more than confidence.':'Not quite. AI output still needs independent checking.'),backgroundColor:a.startsWith('Check')?AppColors.accentGreen:AppColors.warning));if(a.startsWith('Check'))setState(()=>_xp+=10);},child:Align(alignment:Alignment.centerLeft,child:Text(a)))))])));

  Widget _practice() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        'Practice across four industries',
        'Choose a pathway. Each scenario asks you to make a decision and explain why.',
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _industry,
            isExpanded: true,
            items: const [
              'Legal',
              'Finance',
              'Software Engineering',
              'Business',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _industry = v!),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pill('REAL-WORLD SCENARIO'),
            const SizedBox(height: 12),
            Text(
              _scenarioTitle(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scenarioBody(),
              style: const TextStyle(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What is the most responsible next step?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._options().asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selected = e.key),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selected == e.key
                          ? AppColors.accentGreen.withValues(alpha: .1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _selected == e.key
                            ? AppColors.accentGreen
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selected == e.key
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _selected == e.key
                              ? AppColors.accentGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _button(
              'Check my reasoning',
              () {
                final correct = _selected == 0;
                setState(() => _xp += correct ? 20 : 0);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(correct
                        ? 'Good judgement'
                        : 'Pause and reconsider'),
                    content: Text(
                      correct
                          ? 'You chose the evidence-first response. Verify with a trustworthy source, document uncertainty and follow your professional obligations. +20 XP (demo).'
                          : 'Consider evidence, safety and professional responsibility before acting. Review the scenario and try again.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    ],
  );
  String _scenarioTitle()=>switch(_industry){'Legal'=>'An AI cites a case you cannot locate','Finance'=>'An AI summary reports an unusually high return','Software Engineering'=>'AI suggests a library method you do not recognise',_=>'AI recommends a market decision using unclear sources'};
  String _scenarioBody()=>switch(_industry){'Legal'=>'A draft legal memo includes a confident case citation. The deadline is close, but you have not confirmed the case exists or whether it supports the argument.','Finance'=>'An AI-generated investment summary states a strong expected return but provides no methodology and uses old market data.','Software Engineering'=>'An AI-generated code change uses an unfamiliar API and touches authentication logic. Tests have not been run.',_=>'An AI-generated market report recommends entering a new region, but its figures have no clear source or date.'};
  List<String> _options()=>switch(_industry){'Legal'=>['Verify the case in an authoritative legal database and check the relevant passage','Trust the citation because the writing sounds professional','Submit now and correct it only if someone notices'],'Finance'=>['Verify figures, dates, assumptions and source quality before relying on the analysis','Treat the forecast as guaranteed','Share it with clients without further checks'],'Software Engineering'=>['Check official documentation, review security implications and run appropriate tests','Merge immediately because AI wrote it','Remove the tests to meet the deadline'],_=>['Trace key claims to current reliable sources and test assumptions','Use the report without checking its data','Present the recommendation as a certainty']};

  Widget _rewardTile({required String image, required String title, required String subtitle, required String cost, required List<Color> colors, required String note}) => Container(
    margin: const EdgeInsets.only(bottom:12), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:AppColors.border),boxShadow:[BoxShadow(color:colors.first.withValues(alpha:.10),blurRadius:16,offset:const Offset(0,5))]),
    child: Row(children:[Container(width:88,height:92,decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:colors),borderRadius:BorderRadius.circular(18)),child:ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.asset('assets/images/$image.png',fit:BoxFit.cover,width:88,height:92))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:AppColors.primaryNavy)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(fontSize:12,height:1.4,color:AppColors.textSecondary)),const SizedBox(height:9),Row(children:[_pill(cost,color:AppColors.accentGreen),const SizedBox(width:7),Flexible(child:Text(note,style:const TextStyle(fontSize:10,color:AppColors.textSecondary)))])]))]),
  );

  Widget _rewards()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _sectionTitle('Make your XP mean something ✨','A little motivation for every milestone. These reward concepts are demo-only and do not represent real redemption.'),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[AppColors.primaryNavy,Color(0xFF176B68)]),borderRadius:BorderRadius.circular(26)),child:Row(children:[Container(width:64,height:64,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(20)),child:const Center(child:Text('⚡',style:TextStyle(fontSize:34))),),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('YOUR LEARNING WALLET',style:TextStyle(color:AppColors.accentCyan,fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1.4)),Text('$_xp XP',style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Colors.white)),const Text('Level 2 · Verification Explorer',style:TextStyle(color:Colors.white70,fontSize:12))]))])),
    const SizedBox(height:20), _sectionTitle('Choose your feel-good goal','Collect ideas for rewards, play, or giving back.'),
    _rewardTile(image:'reward_coffee',title:'Coffee break',subtitle:'A Starbucks-style coffee reward concept for celebrating a learning streak.',cost:'500 XP',colors:const [Color(0xFFE8F3E9),Color(0xFFB8DCC7)],note:'Illustrative mock-up'),
    _rewardTile(image:'reward_paws',title:'Paws for a cause',subtitle:'A demo concept for supporting an animal rescue or shelter once a verified partner is available.',cost:'800 XP',colors:const [Color(0xFFFFE7C9),Color(0xFFFFC8A6)],note:'No donation made'),
    _rewardTile(image:'reward_game',title:'Game night',subtitle:'A gaming reward concept inspired by cozy sandbox adventures and indie games.',cost:'650 XP',colors:const [Color(0xFFE7DFFF),Color(0xFFC9D7FF)],note:'No game code included'),
    _rewardTile(image:'reward_impact',title:'Community impact',subtitle:'Future option to support a vetted organisation such as Gift of the Givers, subject to an approved partnership and transparent funding.',cost:'1,000 XP',colors:const [Color(0xFFD7F7E9),Color(0xFFB6E5E8)],note:'Partner needed'),
    _rewardTile(image:'reward_grocery',title:'Everyday essentials',subtitle:'Illustrative grocery voucher concept for a future verified rewards partner.',cost:'1,400 XP',colors:const [Color(0xFFE2F8E8),Color(0xFFB6E7CB)],note:'Partner required'),
    _rewardTile(image:'reward_fuel',title:'Fuel your next move',subtitle:'A petrol voucher concept for celebrating consistent practice and progress.',cost:'1,800 XP',colors:const [Color(0xFFFFE8C2),Color(0xFFFFC98F)],note:'Partner required'),
    _rewardTile(image:'reward_m365',title:'Microsoft 365 boost',subtitle:'A productivity-software voucher or subscription concept for future learners.',cost:'2,400 XP',colors:const [Color(0xFFDDEBFF),Color(0xFFB7D0FF)],note:'Availability varies'),
    _rewardTile(image:'reward_workshop',title:'Workshop pass',subtitle:'A future ticket to an AI, software, career or professional-skills workshop.',cost:'2,000 XP',colors:const [Color(0xFFEDE3FF),Color(0xFFD6C2FF)],note:'Workshop partner needed'),
    _rewardTile(image:'reward_gamecredit',title:'Game store credit',subtitle:'A digital gaming credit concept for reaching a higher learning milestone.',cost:'2,200 XP',colors:const [Color(0xFFFFE1EE),Color(0xFFFFC0D9)],note:'No code included'),
    const SizedBox(height:4), _sectionTitle('Milestones unlocked','Keep learning to unlock new badges.'),
    ...[('Starter','100 XP','Your first steps count',Icons.flag_rounded,true),('Verifier','300 XP','Build evidence-first habits',Icons.verified_rounded,_xp>=300),('Critical Thinker','600 XP','Complete an AI Lab milestone',Icons.psychology_rounded,_xp>=600)].map((r)=>_card(child:Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:r.$5?AppColors.accentGreen.withValues(alpha:.15):AppColors.background,borderRadius:BorderRadius.circular(15)),child:Icon(r.$4,color:r.$5?AppColors.primaryNavy:AppColors.silver)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.$1,style:const TextStyle(fontWeight:FontWeight.w900)),Text(r.$3,style:const TextStyle(fontSize:12,color:AppColors.textSecondary)),const SizedBox(height:6),_pill(r.$2,color:r.$5?AppColors.accentGreen:AppColors.silver)])),if(r.$5)const Icon(Icons.check_circle,color:AppColors.accentGreen)]))),
    Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.warning.withValues(alpha:.08),borderRadius:BorderRadius.circular(15)),child:const Text('Demo notice: XP has no cash value. Rewards, game offers and donations are concepts only. Real redemption requires an approved partner, funding, clear terms and backend validation.',style:TextStyle(fontSize:11,height:1.45,color:AppColors.textSecondary))),
  ]);


  Widget _history()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_sectionTitle('Your recent practice','A clean history of the work you do and what to improve next.'),...[
    ('Source-checking basics','Software Engineering','82%','Passed',AppColors.accentGreen),('AI-generated report review','Business','55%','Review recommended',AppColors.warning),('Evidence and confidentiality','Legal','—','In progress',AppColors.info),('Financial claim analysis','Finance','91%','Passed',AppColors.accentGreen)
  ].map((h)=>_card(child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:h.$5.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(Icons.assignment_turned_in_rounded,color:h.$5)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h.$1,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13)),const SizedBox(height:4),Text(h.$2,style:const TextStyle(fontSize:11,color:AppColors.textSecondary)),const SizedBox(height:6),_pill(h.$4,color:h.$5)])),Text(h.$3,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16,color:AppColors.primaryNavy))]))),const Text('Sample history for layout preview. Connect this screen to the real attempt-history endpoint to display a user’s actual records.',style:TextStyle(fontSize:11,color:AppColors.textSecondary,height:1.4))]);
}

class _HubDetails { const _HubDetails(this.title,this.kicker,this.headline,this.subtitle,this.icon); final String title,kicker,headline,subtitle; final IconData icon; }
_HubDetails _details(VerifAiHubMode m)=>switch(m){VerifAiHubMode.assistant=>const _HubDetails('AI Assistant','Think clearly with AI','Your AI thinking partner','Explore ideas, challenge assumptions and learn how to verify what matters.',Icons.auto_awesome_rounded),VerifAiHubMode.verify=>const _HubDetails('Verification Studio','Evidence before confidence','Make every claim earn your trust','Review documents, claims, AI responses and sources—with uncertainty made visible.',Icons.fact_check_rounded),VerifAiHubMode.lab=>const _HubDetails('AI Lab','Learn by doing','Build practical AI judgement','Short interactive workshops in responsible AI, machine learning, research and fact-checking.',Icons.science_rounded),VerifAiHubMode.practice=>const _HubDetails('Industry Practice','Real work. Better judgement.','Practice decisions that matter','Explore realistic scenarios across Legal, Finance, Software Engineering and Business.',Icons.psychology_alt_rounded),VerifAiHubMode.rewards=>const _HubDetails('Rewards','Progress with purpose','Every practice session counts','Earn XP, unlock milestones and build skills you can explain—not just collect badges.',Icons.workspace_premium_rounded),VerifAiHubMode.history=>const _HubDetails('Task History','Your learning, in context','See how your judgement grows','Review attempts, identify patterns and choose what to practise next.',Icons.history_rounded)};
