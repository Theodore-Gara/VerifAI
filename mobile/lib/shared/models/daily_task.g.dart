// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyTaskImpl _$$DailyTaskImplFromJson(Map<String, dynamic> json) =>
    _$DailyTaskImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      scenario: json['scenario'] as String?,
      dimension: json['dimension'] as String,
      format: json['format'] as String? ?? 'choice',
      embeddedFlaw: json['embedded_flaw'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => TaskOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      aiOutputLines: (json['ai_output_lines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trackName: json['trackName'] as String?,
      difficulty: json['difficulty'] as String?,
      feature: json['feature'] as String?,
      trackId: (json['trackId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DailyTaskImplToJson(_$DailyTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'scenario': instance.scenario,
      'dimension': instance.dimension,
      'format': instance.format,
      'embedded_flaw': instance.embeddedFlaw,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'ai_output_lines': instance.aiOutputLines,
      'trackName': instance.trackName,
      'difficulty': instance.difficulty,
      'feature': instance.feature,
      'trackId': instance.trackId,
    };
