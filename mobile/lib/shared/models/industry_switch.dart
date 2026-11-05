// Industry-switch and tutorial state from the Sprint 2 backend. Plain classes,
// no codegen.

/// Per-track tutorial state from `GET/PUT /api/onboarding/tour`.
class TutorialState {
  final String tourKey;
  final String? status; // completed | skipped | null
  final bool shouldOffer;
  final String? updatedAt;
  final int? trackId;

  const TutorialState({
    this.tourKey = 'industry',
    this.status,
    this.shouldOffer = false,
    this.updatedAt,
    this.trackId,
  });

  bool get completed => status == 'completed';
  bool get skipped => status == 'skipped';

  factory TutorialState.fromJson(Map<String, dynamic> json) => TutorialState(
        tourKey: json['tour_key'] as String? ?? 'industry',
        status: json['status'] as String?,
        shouldOffer: json['should_offer'] as bool? ?? false,
        updatedAt: json['updated_at'] as String?,
        trackId: int.tryParse('${json['track_id']}'),
      );
}

/// Response of `PUT /api/users/industry`.
class IndustrySwitchResult {
  final int trackId;
  final String trackName;
  final int readinessScore;
  final String tier;
  final TutorialState? tour;

  /// Values that carry across a switch: xp, level, streak, tokens.
  final List<String> kept;
  final Map<String, dynamic> keptValues;

  const IndustrySwitchResult({
    required this.trackId,
    required this.trackName,
    this.readinessScore = 0,
    this.tier = 'Novice',
    this.tour,
    this.kept = const [],
    this.keptValues = const {},
  });

  factory IndustrySwitchResult.fromJson(Map<String, dynamic> json) {
    final track = (json['track'] as Map?)?.cast<String, dynamic>() ?? const {};
    final progress =
        (json['progress'] as Map?)?.cast<String, dynamic>() ?? const {};
    return IndustrySwitchResult(
      trackId: _int(track['id']),
      trackName: track['name'] as String? ?? '',
      readinessScore: _int(progress['readiness_score']),
      tier: progress['tier'] as String? ?? 'Novice',
      tour: json['tour'] == null
          ? null
          : TutorialState.fromJson(
              Map<String, dynamic>.from(json['tour'] as Map)),
      kept: ((json['kept'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      keptValues:
          (json['kept_values'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse('$value') ?? fallback;
