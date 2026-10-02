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
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      dailyTask: _dailyTaskFromJson(json['dailyTask'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$$DashboardDataImplToJson(_$DashboardDataImpl instance) =>
    <String, dynamic>{
      'overallScore': instance.overallScore,
      'dimensionScores': instance.dimensionScores,
      'streakDays': instance.streakDays,
      'currentXp': instance.currentXp,
      'level': instance.level,
      'completedTasks': instance.completedTasks,
      'dailyTask': _dailyTaskToJson(instance.dailyTask),
    };
