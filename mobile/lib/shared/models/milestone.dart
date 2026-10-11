// A track milestone from `GET /api/achievements/milestones`. Plain class.

class Milestone {
  final String code;
  final String name;
  final String description;
  final int target;
  final int current;
  final bool achieved;

  const Milestone({
    required this.code,
    required this.name,
    required this.description,
    required this.target,
    required this.current,
    required this.achieved,
  });

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        target: _int(json['target']),
        current: _int(json['current']),
        achieved: json['achieved'] as bool? ?? false,
      );
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse('$value') ?? fallback;
