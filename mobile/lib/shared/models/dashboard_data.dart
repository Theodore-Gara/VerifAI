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
    @JsonKey(
      fromJson: _dailyTaskFromJson,
      toJson: _dailyTaskToJson,
    )
    DailyTask? dailyTask,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) => _$DashboardDataFromJson(json);
}

DailyTask? _dailyTaskFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return DailyTask.fromJson(json);
}

Map<String, dynamic>? _dailyTaskToJson(DailyTask? task) => task?.toJson();