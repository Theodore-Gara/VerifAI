import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';

class WellnessCenterScreen extends StatefulWidget {
  const WellnessCenterScreen({super.key});

  @override
  State<WellnessCenterScreen> createState() => _WellnessCenterScreenState();
}

class _WellnessCenterScreenState extends State<WellnessCenterScreen> {
  static const _moods = [
    ('Great', '😊'),
    ('Calm', '😌'),
    ('Okay', '🙂'),
    ('Stressed', '😣'),
    ('Tired', '😴'),
    ('Low', '😔'),
  ];

  String? _mood;
  bool _saved = false;
  bool _loadingMood = true;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);
  String get _moodKey => 'wellness_mood_$_today';
  String get _journalKey => 'wellness_journal_$_today';

  @override
  void initState() {
    super.initState();
    _loadTodayMood();
  }

  Future<void> _loadTodayMood() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _mood = preferences.getString(_moodKey);
        _saved = _mood != null;
        _loadingMood = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMood = false);
      _showMessage('Could not load today’s check-in.');
    }
  }

  Future<void> _saveMood() async {
    final mood = _mood;
    if (mood == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_moodKey, mood);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) _showMessage('Could not save your check-in. Try again.');
    }
  }

  Future<void> _saveJournal(String text) async {
    final reflection = text.trim();
    if (reflection.isEmpty) {
      _showMessage('Write a reflection before saving.');
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_journalKey, reflection);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Reflection saved on this device.');
    } catch (_) {
      if (mounted) _showMessage('Could not save your reflection. Try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Open navigation menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _showNavigation(context),
        ),
        title: const Text(
          'Wellness Centre',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Ask Vera',
            onPressed: () => context.push('/assistant'),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          _heroCard(context),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'How are you feeling today?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF18392F),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No right or wrong answer. Take a moment to check in with yourself.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.12,
            children: [
              for (final mood in _moods) _moodTile(mood.$1, mood.$2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loadingMood || _mood == null ? null : _saveMood,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF176B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                _saved ? 'Check-in saved on this device' : 'Save my check-in',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'A little care goes a long way',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF18392F),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _activityCard(
            title: 'Mindful breathing',
            subtitle: 'A gentle 60-second reset between tasks.',
            image:
                'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
            icon: Icons.air_rounded,
            onTap: () => _showBreathing(context),
          ),
          _activityCard(
            title: 'Journal your thoughts',
            subtitle: 'Make a little space to reflect without judgement.',
            image:
                'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=800&q=80',
            icon: Icons.menu_book_rounded,
            onTap: () => _showJournal(context),
          ),
          _activityCard(
            title: 'Step outside for a moment',
            subtitle: 'A little daylight and movement can help you reset.',
            image:
                'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=800&q=80',
            icon: Icons.nature_people_rounded,
            onTap: () => _showInfo(
              context,
              'A gentle reset',
              'If you can, take a comfortable short walk, notice what you can '
                  'see and hear, and give yourself permission not to solve '
                  'everything right now.',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEE8),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Text(
              'Your check-ins and reflections are stored in this app’s local '
              'device preferences. They are not synced or encrypted. VerifAI '
              'Wellness is for general reflection, not medical or mental-health '
              'diagnosis or treatment. If you are struggling, consider reaching '
              'out to someone you trust or a qualified professional.',
              style: TextStyle(
                color: Color(0xFF52665C),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF124F3D),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0C2824).withValues(alpha: 0.94),
                  const Color(0xFF124F3D).withValues(alpha: 0.72),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR SPACE TO RESET',
                  style: TextStyle(
                    color: Color(0xFFD6F3E5),
                    letterSpacing: 1.4,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Breathe.\nYou’re allowed to pause.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Your wellbeing matters just as much as your progress. '
                  'Take a moment for yourself.',
                  style: TextStyle(
                    color: Color(0xFFE0EEE7),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _showBreathing(context),
                  icon: const Icon(Icons.air_rounded),
                  label: const Text('Take a mindful pause'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodTile(String label, String emoji) {
    final selected = _mood == label;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label mood',
      child: InkWell(
        onTap: () => setState(() {
          _mood = label;
          _saved = false;
        }),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDF3E8) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? const Color(0xFF18805D) : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 27)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF19372F),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityCard({
    required String title,
    required String subtitle,
    required String image,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 112,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: const Color(0xFFDCE9DF),
                  child: Icon(icon, size: 32, color: const Color(0xFF176B55)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17382E),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'EXPLORE',
                      style: TextStyle(
                        color: Color(0xFF14745A),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        fontSize: 10,
                      ),
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

  void _showNavigation(BuildContext context) {
    const destinations = [
      ('Home', Icons.home_rounded, '/dashboard'),
      (
        'Verification Studio',
        Icons.verified_user_rounded,
        '/verification-studio'
      ),
      ('Ask Vera', Icons.auto_awesome_rounded, '/assistant'),
      ('AI Lab', Icons.science_rounded, '/ai-lab'),
      ('Progress', Icons.insights_rounded, '/progress'),
      ('Rewards', Icons.emoji_events_rounded, '/rewards'),
      ('Wellness Centre', Icons.spa_rounded, '/wellness'),
      ('Profile & settings', Icons.person_rounded, '/profile'),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 14),
              child: Text(
                'VERIFAI  •  NAVIGATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
            for (final destination in destinations)
              ListTile(
                leading: Icon(destination.$2, color: AppColors.accentGreen),
                title: Text(
                  destination.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(destination.$3);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showBreathing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air_rounded,
                  color: AppColors.accentGreen, size: 42),
              const SizedBox(height: AppSpacing.md),
              Text(
                'One mindful minute',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Relax your shoulders. Breathe in gently for four counts, then '
                'breathe out slowly for six. Repeat at a comfortable pace. '
                'Stop if you feel dizzy or uncomfortable.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.55, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('I’m ready'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJournal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: _JournalReflectionSheet(
            onSave: _saveJournal,
            titleStyle: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _JournalReflectionSheet extends StatefulWidget {
  const _JournalReflectionSheet({
    required this.onSave,
    required this.titleStyle,
  });

  final ValueChanged<String> onSave;
  final TextStyle? titleStyle;

  @override
  State<_JournalReflectionSheet> createState() =>
      _JournalReflectionSheetState();
}

class _JournalReflectionSheetState extends State<_JournalReflectionSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A moment to reflect',
          style: widget.titleStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('What is one thing you need right now?'),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          maxLines: 5,
          maxLength: 1200,
          decoration: const InputDecoration(
            hintText: 'Write privately on this device…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onSave(_controller.text),
            child: const Text('Save reflection on this device'),
          ),
        ),
      ],
    );
  }
}
