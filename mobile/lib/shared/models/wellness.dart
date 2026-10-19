// Wellness data: daily mood check-ins, private journal entries and the weekly
// self-care summary. Plain classes (no codegen).
class MoodCheckin {
  final String date; // YYYY-MM-DD, the learner's local day
  final String mood;
  final String updatedAt;

  const MoodCheckin({
    required this.date,
    required this.mood,
    this.updatedAt = '',
  });

  bool get isToday => date == _todayIso();

  factory MoodCheckin.fromJson(Map<String, dynamic> json) => MoodCheckin(
        date: json['date'] as String? ?? '',
        mood: json['mood'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class JournalEntry {
  final String date; // YYYY-MM-DD
  final String content;
  final String updatedAt;

  const JournalEntry({
    required this.date,
    required this.content,
    this.updatedAt = '',
  });

  bool get isToday => date == _todayIso();

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        date: json['date'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class WellnessWeek {
  final int days;
  final int total;
  final Map<String, int> counts;

  const WellnessWeek({
    this.days = 7,
    this.total = 0,
    this.counts = const {},
  });

  factory WellnessWeek.fromJson(Map<String, dynamic> json) {
    final activities = json['activities'] as List<dynamic>? ?? const [];
    final counts = <String, int>{};
    for (final row in activities) {
      final map = Map<String, dynamic>.from(row as Map);
      final activity = map['activity'] as String? ?? '';
      final count = int.tryParse('${map['count']}') ?? 0;
      if (activity.isNotEmpty) counts[activity] = count;
    }
    return WellnessWeek(
      days: int.tryParse('${json['days']}') ?? 7,
      total: int.tryParse('${json['total']}') ?? 0,
      counts: counts,
    );
  }
}

String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);
