// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardDataImpl _$$DashboardDataImplFromJson(Map<String, dynamic> json) =>
    _$DashboardDataImpl(
      overallScore: (json['overallScore'] as num).toInt(),
      dimensionScores: Map<String, int>.from(json['dimensionScores'] as Map),
      streakDays: (json['streakDays'] as num).toInt(),
      currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xpIntoLevel: (json['xpIntoLevel'] as num?)?.toInt() ?? 0,
      xpForNextLevel: (json['xpForNextLevel'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String?,
      dailyTask: _dailyTaskFromJson(json['dailyTask'] as Map<String, dynamic>?),
      tasks: json['tasks'] == null
          ? const []
          : _dailyTaskListFromJson(json['tasks'] as List?),
    );

Map<String, dynamic> _$$DashboardDataImplToJson(_$DashboardDataImpl instance) =>
    <String, dynamic>{
      'overallScore': instance.overallScore,
      'dimensionScores': instance.dimensionScores,
      'streakDays': instance.streakDays,
      'currentXp': instance.currentXp,
      'level': instance.level,
      'xpIntoLevel': instance.xpIntoLevel,
      'xpForNextLevel': instance.xpForNextLevel,
      'completedTasks': instance.completedTasks,
      'tier': instance.tier,
      'dailyTask': _dailyTaskToJson(instance.dailyTask),
      'tasks': _dailyTaskListToJson(instance.tasks),
    };
