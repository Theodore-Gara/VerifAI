// Daily activity from `GET /api/progress/me/activity`. Plain classes.

class ActivityDay {
  final String date;
  final int attempts;
  final int xpEarned;
  final int passed;

  const ActivityDay({
    required this.date,
    required this.attempts,
    required this.xpEarned,
    required this.passed,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) => ActivityDay(
        date: (json['activity_date'] as String? ?? '').split('T').first,
        attempts: _int(json['attempts']),
        xpEarned: _int(json['xp_earned']),
        passed: _int(json['passed']),
      );
}

class ActivityData {
  final int days;
  final int streak;
  final String? lastActivityDate;
  final List<ActivityDay> activity;

  const ActivityData({
    required this.days,
    required this.streak,
    required this.lastActivityDate,
    required this.activity,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>? ?? const {};
    final rows = json['activity'] as List<dynamic>? ?? const [];
    return ActivityData(
      days: _int(json['days']),
      streak: _int(streak['current']),
      lastActivityDate: streak['last_activity_date'] as String?,
      activity: rows
          .map((e) => ActivityDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// XP keyed by date (`yyyy-MM-dd`), for the weekly chart.
  Map<String, int> get xpByDate => {
        for (final day in activity) day.date: day.xpEarned,
      };
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse('$value') ?? fallback;
