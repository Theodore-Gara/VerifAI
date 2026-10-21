// Unified activity history. Plain class (no codegen).

/// One scored attempt, fetched by id so the feedback screen survives a deep
/// link, a restart or process death (the result object only exists in memory).
class AttemptFeedback {
  final int id;
  final String title;
  final String? feature;
  final int score;
  final bool passed;
  final String feedback;
  final int xpEarned;
  final String submittedAt;

  const AttemptFeedback({
    required this.id,
    required this.title,
    required this.score,
    required this.passed,
    required this.feedback,
    this.feature,
    this.xpEarned = 0,
    this.submittedAt = '',
  });

  factory AttemptFeedback.fromJson(Map<String, dynamic> json) =>
      AttemptFeedback(
        id: int.tryParse('${json['id']}') ?? 0,
        title: json['title'] as String? ?? '',
        feature: json['feature'] as String?,
        score: int.tryParse('${json['score']}') ?? 0,
        passed: json['passed'] as bool? ?? false,
        feedback: json['feedback'] as String? ?? '',
        xpEarned: int.tryParse('${json['xp_earned']}') ?? 0,
        submittedAt: json['submitted_at'] as String? ?? '',
      );
}

class HistoryEntry {
  final String type; // task | activity | capstone
  final int id;
  final String title;
  final String? feature;
  final int? score;
  final bool? passed;
  final int xpEarned;
  final String createdAt;

  const HistoryEntry({
    required this.type,
    required this.id,
    required this.title,
    this.feature,
    this.score,
    this.passed,
    this.xpEarned = 0,
    this.createdAt = '',
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        type: json['type'] as String? ?? 'task',
        id: int.tryParse('${json['id']}') ?? 0,
        title: json['title'] as String? ?? '',
        feature: json['feature'] as String?,
        score: json['score'] == null ? null : int.tryParse('${json['score']}'),
        passed: json['passed'] as bool?,
        xpEarned: int.tryParse('${json['xp_earned']}') ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
}
