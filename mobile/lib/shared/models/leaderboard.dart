// Leaderboard rows from `GET /api/leaderboard`. Plain classes (no codegen).

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final int level;
  final int xp;
  final int streak;
  final int readinessScore;
  final String tier;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.level,
    required this.xp,
    required this.streak,
    required this.readinessScore,
    required this.tier,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final userId = _int(json['user_id']);
    return LeaderboardEntry(
      rank: _int(json['rank']),
      userId: userId,
      name: json['display_name'] as String? ?? 'Unknown',
      level: _int(json['level'], fallback: 1),
      xp: _int(json['xp']),
      streak: _int(json['streak']),
      readinessScore: _int(json['readiness_score']),
      tier: json['tier'] as String? ?? 'Novice',
      isCurrentUser: currentUserId != null && userId == currentUserId,
    );
  }
}

class LeaderboardData {
  final int? trackId;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry me;

  const LeaderboardData({
    required this.trackId,
    required this.entries,
    required this.me,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final meJson = json['me'] as Map<String, dynamic>? ?? const {};
    final meId = _int(meJson['user_id']);
    final rawEntries = json['leaderboard'] as List<dynamic>? ?? const [];
    return LeaderboardData(
      trackId: json['track_id'] == null ? null : _int(json['track_id']),
      entries: rawEntries
          .map((e) => LeaderboardEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
                currentUserId: meId,
              ))
          .toList(),
      me: LeaderboardEntry.fromJson(meJson),
    );
  }
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse('$value') ?? fallback;
