// Unified activity history. Plain class (no codegen).
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
