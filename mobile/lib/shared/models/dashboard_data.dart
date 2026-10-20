import 'package:freezed_annotation/freezed_annotation.dart';
import 'daily_task.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    required int overallScore,
    required Map<String, int> dimensionScores,
    required int streakDays,
    @Default(0) int currentXp,
    @Default(1) int level,
    // Progress inside the current level, straight from the server's level
    // curve, so the app never re-derives it (and cannot drift from the backend).
    @Default(0) int xpIntoLevel,
    @Default(0) int xpForNextLevel,
    @Default(0) int completedTasks,
    String? tier,
    @JsonKey(
      fromJson: _dailyTaskFromJson,
      toJson: _dailyTaskToJson,
    )
    DailyTask? dailyTask,
    @JsonKey(
      fromJson: _dailyTaskListFromJson,
      toJson: _dailyTaskListToJson,
    )
    @Default([])
    List<DailyTask> tasks,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}

DailyTask? _dailyTaskFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return DailyTask.fromJson(json);
}

Map<String, dynamic>? _dailyTaskToJson(DailyTask? task) => task?.toJson();

List<DailyTask> _dailyTaskListFromJson(List<dynamic>? json) => [
      for (final item in json ?? const [])
        if (item != null)
          DailyTask.fromJson(Map<String, dynamic>.from(item as Map)),
    ];

List<Map<String, dynamic>> _dailyTaskListToJson(List<DailyTask> tasks) =>
    tasks.map((task) => task.toJson()).toList();
