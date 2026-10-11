import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_task.freezed.dart';
part 'daily_task.g.dart';

class TaskOption {
  final int id;
  final String label;
  final String? kind;

  const TaskOption({required this.id, required this.label, this.kind});

  factory TaskOption.fromJson(Map<String, dynamic> json) => TaskOption(
        id: (json['id'] as num).toInt(),
        label: json['label'] as String,
        kind: json['kind'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (kind != null) 'kind': kind,
      };
}

@freezed
class DailyTask with _$DailyTask {
  @JsonSerializable(explicitToJson: true)
  const factory DailyTask({
    required int id,
    required String title,
    String? scenario,
    required String dimension,
    @Default('choice') String format,
    @JsonKey(name: 'embedded_flaw') String? embeddedFlaw,
    @Default([]) List<TaskOption> options,
    @JsonKey(name: 'ai_output_lines') @Default([]) List<String> aiOutputLines,
    String? trackName,
    String? difficulty,
    String? feature,
    int? trackId,
    @JsonKey(name: 'is_repeat') @Default(false) bool isRepeat,
  }) = _DailyTask;

  factory DailyTask.fromJson(Map<String, dynamic> json) =>
      _$DailyTaskFromJson(json);
}
