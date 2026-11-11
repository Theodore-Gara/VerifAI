// Stage-based readiness roadmap from GET /api/roadmap. Plain classes.
class RoadmapAction {
  final String label;
  final String? route;

  const RoadmapAction({required this.label, this.route});

  factory RoadmapAction.fromJson(Map<String, dynamic> json) => RoadmapAction(
        label: json['label'] as String? ?? '',
        route: json['route'] as String?,
      );
}

class RoadmapMilestone {
  final String code;
  final String title;
  final String description;
  final String status; // complete | current | up_next | locked
  final int current;
  final int target;
  final String unit;
  final RoadmapAction? action;

  const RoadmapMilestone({
    required this.code,
    required this.title,
    this.description = '',
    this.status = 'locked',
    this.current = 0,
    this.target = 1,
    this.unit = 'item',
    this.action,
  });

  bool get complete => status == 'complete';
  bool get isCurrent => status == 'current';
  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();

  factory RoadmapMilestone.fromJson(Map<String, dynamic> json) =>
      RoadmapMilestone(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'locked',
        current: _int(json['current']),
        target: _int(json['target'], fallback: 1),
        unit: json['unit'] as String? ?? 'item',
        action: json['action'] == null
            ? null
            : RoadmapAction.fromJson(
                Map<String, dynamic>.from(json['action'] as Map)),
      );
}

class RoadmapStage {
  final String code;
  final String title;
  final String outcome;
  final int order;
  final String status; // complete | active | locked
  final List<RoadmapMilestone> milestones;

  const RoadmapStage({
    required this.code,
    required this.title,
    this.outcome = '',
    this.order = 0,
    this.status = 'locked',
    this.milestones = const [],
  });

  bool get complete => status == 'complete';
  bool get active => status == 'active';

  factory RoadmapStage.fromJson(Map<String, dynamic> json) => RoadmapStage(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        outcome: json['outcome'] as String? ?? '',
        order: _int(json['order']),
        status: json['status'] as String? ?? 'locked',
        milestones: ((json['milestones'] as List<dynamic>?) ?? const [])
            .map((e) =>
                RoadmapMilestone.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class RoadmapNextAction {
  final String stage;
  final String milestone;
  final String label;
  final String? route;

  const RoadmapNextAction({
    required this.stage,
    required this.milestone,
    required this.label,
    this.route,
  });

  factory RoadmapNextAction.fromJson(Map<String, dynamic> json) =>
      RoadmapNextAction(
        stage: json['stage'] as String? ?? '',
        milestone: json['milestone'] as String? ?? '',
        label: json['label'] as String? ?? '',
        route: json['route'] as String?,
      );
}

class RoadmapSummary {
  final int currentStage;
  final int stagesCompleted;
  final int milestonesCompleted;
  final int milestonesTotal;
  final int percent;
  final int readinessScore;
  final String tier;

  const RoadmapSummary({
    this.currentStage = 1,
    this.stagesCompleted = 0,
    this.milestonesCompleted = 0,
    this.milestonesTotal = 0,
    this.percent = 0,
    this.readinessScore = 0,
    this.tier = 'Novice',
  });

  factory RoadmapSummary.fromJson(Map<String, dynamic> json) => RoadmapSummary(
        currentStage: _int(json['current_stage'], fallback: 1),
        stagesCompleted: _int(json['stages_completed']),
        milestonesCompleted: _int(json['milestones_completed']),
        milestonesTotal: _int(json['milestones_total']),
        percent: _int(json['percent']),
        readinessScore: _int(json['readiness_score']),
        tier: json['tier'] as String? ?? 'Novice',
      );
}

class RoadmapCredential {
  final String title;
  final String? description;
  final bool unlocked;

  const RoadmapCredential({
    this.title = 'AI Readiness Passport',
    this.description,
    this.unlocked = false,
  });

  factory RoadmapCredential.fromJson(Map<String, dynamic> json) =>
      RoadmapCredential(
        title: json['title'] as String? ?? 'AI Readiness Passport',
        description: json['description'] as String?,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class RoadmapData {
  final int trackId;
  final String trackName;
  final RoadmapSummary summary;
  final List<RoadmapStage> stages;
  final RoadmapNextAction? nextAction;
  final RoadmapCredential? credential;

  const RoadmapData({
    this.trackId = 0,
    this.trackName = '',
    this.summary = const RoadmapSummary(),
    this.stages = const [],
    this.nextAction,
    this.credential,
  });

  factory RoadmapData.fromJson(Map<String, dynamic> json) {
    final track = (json['track'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RoadmapData(
      trackId: _int(track['id']),
      trackName: track['name'] as String? ?? '',
      summary: RoadmapSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {}),
      stages: ((json['stages'] as List<dynamic>?) ?? const [])
          .map(
              (e) => RoadmapStage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      nextAction: json['next_action'] == null
          ? null
          : RoadmapNextAction.fromJson(
              Map<String, dynamic>.from(json['next_action'] as Map)),
      credential: json['credential'] == null
          ? null
          : RoadmapCredential.fromJson(
              Map<String, dynamic>.from(json['credential'] as Map)),
    );
  }
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse('$value') ?? fallback;
