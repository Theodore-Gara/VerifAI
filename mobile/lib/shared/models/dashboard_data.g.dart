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
      dailyTask: _dailyTaskFromJson(json['dailyTask'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$$DashboardDataImplToJson(_$DashboardDataImpl instance) =>
    <String, dynamic>{
      'overallScore': instance.overallScore,
      'dimensionScores': instance.dimensionScores,
      'streakDays': instance.streakDays,
      'dailyTask': _dailyTaskToJson(instance.dailyTask),
    };
