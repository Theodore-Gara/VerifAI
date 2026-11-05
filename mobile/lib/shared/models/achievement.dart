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

  /// Set by the full catalog (`GET /api/achievements`). The earned-only
  /// endpoints omit the flag, so `earned_at` is used as a fallback.
  final bool earned;

  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.earnedAt,
    this.earned = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final earnedAt = json['earned_at'] as String?;
    return Achievement(
      id: int.tryParse('${json['id']}') ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      earnedAt: earnedAt,
      earned: json['earned'] as bool? ?? earnedAt != null,
    );
  }
}
