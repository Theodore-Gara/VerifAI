import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/wellness/providers.dart';
import 'package:verifai/shared/models.dart';

class WellnessCenterScreen extends ConsumerStatefulWidget {
  const WellnessCenterScreen({super.key});

  @override
  ConsumerState<WellnessCenterScreen> createState() =>
      _WellnessCenterScreenState();
}

class _WellnessCenterScreenState extends ConsumerState<WellnessCenterScreen> {
  static const _moods = [
    ('Great', '😊'),
    ('Calm', '😌'),
    ('Okay', '🙂'),
    ('Stressed', '😣'),
    ('Tired', '😴'),
    ('Low', '😔'),
  ];

  String? _selectedMood;
  bool _savingMood = false;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  String _emojiFor(String mood) {
    for (final entry in _moods) {
      if (entry.$1 == mood) return entry.$2;
    }
    return '🙂';
  }

  MoodCheckin? _todayCheckin(List<MoodCheckin> checkins) {
    for (final checkin in checkins) {
      if (checkin.isToday) return checkin;
    }
    return null;
  }

  Future<void> _saveMood(String mood) async {
    setState(() => _savingMood = true);
    try {
      await ref.read(apiClientProvider).saveMoodCheckin(mood, date: _today);
      if (!mounted) return;
      ref.invalidate(moodHistoryProvider);
      _showMessage('Check-in saved.');
    } catch (_) {
      if (mounted) _showMessage('Could not save your check-in. Try again.');
    } finally {
      if (mounted) setState(() => _savingMood = false);
    }
  }

  Future<bool> _saveJournal(String text) async {
    final reflection = text.trim();
    if (reflection.isEmpty) {
      _showMessage('Write a reflection before saving.');
      return false;
    }

    try {
      final api = ref.read(apiClientProvider);
      await api.saveJournalEntry(reflection, date: _today);
      await api.logWellnessActivity('journal');
      if (!mounted) return true;
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(wellnessWeekProvider);
      _showMessage('Reflection saved to your account.');
      return true;
    } catch (_) {
      if (mounted) _showMessage('Could not save your reflection. Try again.');
      return false;
    }
  }

  Future<void> _logActivity(String activity) async {
    try {
      await ref.read(apiClientProvider).logWellnessActivity(activity);
      if (!mounted) return;
      ref.invalidate(wellnessWeekProvider);
      _showMessage('Logged. Nicely done.');
    } catch (_) {
      if (mounted) _showMessage('Could not log that just now.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final checkins = ref.watch(moodHistoryProvider).valueOrNull ?? const <MoodCheckin>[];
    final journalEntries =
        ref.watch(journalEntriesProvider).valueOrNull ?? const <JournalEntry>[];
    final weekAsync = ref.watch(wellnessWeekProvider);
    final today = _todayCheckin(checkins);
    final selectedMood = _selectedMood ?? today?.mood;
    final saved = today != null && today.mood == selectedMood;

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
              for (final mood in _moods)
                _moodTile(mood.$1, mood.$2, mood.$1 == selectedMood),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedMood == null || _savingMood || saved
                  ? null
                  : () => _saveMood(selectedMood),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF176B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                _savingMood
                    ? 'Saving…'
                    : saved
                        ? 'Check-in saved'
                        : 'Save my check-in',
              ),
            ),
          ),
          if (checkins.length > 1) _historyStrip(checkins),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'A little care goes a long way',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF18392F),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _weekSummary(weekAsync),
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
            onTap: () => _showJournal(context, journalEntries),
          ),
          _activityCard(
            title: 'Step outside for a moment',
            subtitle: 'A little daylight and movement can help you reset.',
            image:
                'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=800&q=80',
            icon: Icons.nature_people_rounded,
            onTap: () => _showStepOutside(context),
          ),
          _activityCard(
            title: 'Kind words for yourself',
            subtitle: 'A short affirmation to carry with you today.',
            image:
                'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?auto=format&fit=crop&w=800&q=80',
            icon: Icons.favorite_rounded,
            onTap: () => _showAffirmation(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEE8),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Text(
              'Your check-ins and reflections sync to your VerifAI account and '
              'are private to you. Vera can see your recent moods so she can '
              'support you, but never the contents of your journal. VerifAI '
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

  Widget _weekSummary(AsyncValue<WellnessWeek> weekAsync) {
    final week = weekAsync.valueOrNull;
    final label = week == null
        ? 'Self-care this week: loading…'
        : week.total == 0
            ? 'No self-care logged yet this week'
            : week.total == 1
                ? '1 self-care moment this week'
                : '${week.total} self-care moments this week';
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF52665C),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _historyStrip(List<MoodCheckin> checkins) {
    final recent = checkins.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Recent check-ins',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18392F),
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final checkin = recent[index];
              final isToday = checkin.isToday;
              return Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFDDF3E8) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isToday ? const Color(0xFF18805D) : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _emojiFor(checkin.mood),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isToday ? 'Today' : shortWellnessDate(checkin.date),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF52665C),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _moodTile(String label, String emoji, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label mood',
      child: InkWell(
        onTap: () => setState(() => _selectedMood = label),
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
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        child: _BreathingSheet(onComplete: () => _logActivity('breathing')),
      ),
    );
  }

  void _showJournal(BuildContext context, List<JournalEntry> entries) {
    JournalEntry? todayEntry;
    for (final entry in entries) {
      if (entry.isToday) todayEntry = entry;
    }

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
            initialText: todayEntry?.content ?? '',
            entries: entries,
          ),
        ),
      ),
    );
  }

  void _showStepOutside(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('A gentle reset'),
        content: const Text(
          'If you can, take a comfortable short walk, notice what you can see '
          'and hear, and give yourself permission not to solve everything '
          'right now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logActivity('step_outside');
            },
            child: const Text('I did it'),
          ),
        ],
      ),
    );
  }

  void _showAffirmation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _AffirmationSheet(),
    );
  }
}

String shortWellnessDate(String isoDate) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return isoDate;
  return '$day ${months[month - 1]}';
}

class _JournalReflectionSheet extends StatefulWidget {
  const _JournalReflectionSheet({
    required this.onSave,
    required this.titleStyle,
    required this.initialText,
    required this.entries,
  });

  final Future<bool> Function(String) onSave;
  final TextStyle? titleStyle;
  final String initialText;
  final List<JournalEntry> entries;

  @override
  State<_JournalReflectionSheet> createState() =>
      _JournalReflectionSheetState();
}

class _JournalReflectionSheetState extends State<_JournalReflectionSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
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
            hintText: 'Write privately…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save reflection'),
          ),
        ),
        if (widget.entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'All entries (${widget.entries.length})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              for (final entry in widget.entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(shortWellnessDate(entry.date)),
                  subtitle: Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(shortWellnessDate(entry.date)),
                      content: SingleChildScrollView(child: Text(entry.content)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BreathingSheet extends StatefulWidget {
  const _BreathingSheet({required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<_BreathingSheet> createState() => _BreathingSheetState();
}

class _BreathingSheetState extends State<_BreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breath;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _breath = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    _controller.stop();
    await widget.onComplete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'One mindful minute',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Relax your shoulders. Breathe in gently as the circle grows, '
              'and out slowly as it shrinks. Stop if you feel dizzy or '
              'uncomfortable.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.55, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _breath.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0xFF9AD9BF), Color(0xFF18805D)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _controller.value < 0.4 ? 'Breathe in…' : 'Breathe out…',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF176B4D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$_secondsLeft seconds remaining',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _finishing ? null : _finish,
                child: const Text('Finish'),
              ),
            ),
            TextButton(
              onPressed: _finishing ? null : () => Navigator.of(context).pop(),
              child: const Text('Close without logging'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AffirmationSheet extends StatefulWidget {
  const _AffirmationSheet();

  @override
  State<_AffirmationSheet> createState() => _AffirmationSheetState();
}

class _AffirmationSheetState extends State<_AffirmationSheet> {
  static const _affirmations = [
    'I am allowed to take up space and time.',
    'Progress, not perfection.',
    'One calm breath is enough for now.',
    'I can do hard things, one step at a time.',
    'Rest is part of the work.',
    'I am learning, and that is enough.',
    'My worth is not my output.',
    'I can ask for help when I need it.',
    'Small steps still move me forward.',
    'I deserve the same kindness I give others.',
    'This feeling is temporary; I can be gentle with myself.',
    'I choose progress over pressure today.',
  ];

  final _random = Random();
  late int _index = _random.nextInt(_affirmations.length);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded,
                color: AppColors.accentGreen, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              _affirmations[_index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18392F),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Say it slowly and notice how it lands. You can come back for '
              'another anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(
                  () => _index = (_index + 1) % _affirmations.length,
                ),
                child: const Text('Show another'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
