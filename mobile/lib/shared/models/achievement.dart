/// A single achievement, from `GET /api/achievements/me` or from a task
/// attempt's `newly_earned_achievements`. Plain class (no codegen needed).
class Achievement {
  final int id;
  final String code;
  final String name;
  final String description;

  /// Present when the achievement was earned (`earned_at`); null for the
  /// `newly_earned_achievements` payload, which omits it.
  final String? earnedAt;

  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: int.tryParse('${json['id']}') ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      earnedAt: json['earned_at'] as String?,
    );
  }
}
