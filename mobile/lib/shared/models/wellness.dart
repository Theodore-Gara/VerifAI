// Wellness data: daily mood check-ins, private journal entries and the weekly
// self-care summary. Plain classes (no codegen).
class MoodCheckin {
  final String date; // YYYY-MM-DD
  final String mood;
  final String? note;
  final String updatedAt;

  /// The server's idea of "today" for this response. The device clock is not
  /// used: near midnight, or in another timezone, it disagrees with the day the
  /// server stored the check-in against.
  final String serverToday;

  const MoodCheckin({
    required this.date,
    required this.mood,
    this.note,
    this.updatedAt = '',
    this.serverToday = '',
  });

  bool get isToday => date == _today(serverToday);

  factory MoodCheckin.fromJson(Map<String, dynamic> json, {String? today}) {
    final rawNote = (json['note'] as String?)?.trim();
    return MoodCheckin(
      date: json['date'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      note: rawNote == null || rawNote.isEmpty ? null : rawNote,
      updatedAt: json['updated_at'] as String? ?? '',
      serverToday: today ?? json['today'] as String? ?? '',
    );
  }
}

class JournalEntry {
  final String date; // YYYY-MM-DD
  final String content;
  final String updatedAt;
  final String serverToday;

  const JournalEntry({
    required this.date,
    required this.content,
    this.updatedAt = '',
    this.serverToday = '',
  });

  bool get isToday => date == _today(serverToday);

  factory JournalEntry.fromJson(Map<String, dynamic> json, {String? today}) =>
      JournalEntry(
        date: json['date'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        serverToday: today ?? json['today'] as String? ?? '',
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

// Falls back to the device only when the server did not report its day (an
// older backend); normally [serverToday] is authoritative.
String _today(String serverToday) => serverToday.isNotEmpty
    ? serverToday
    : DateTime.now().toIso8601String().substring(0, 10);
