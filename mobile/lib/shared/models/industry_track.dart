import 'package:freezed_annotation/freezed_annotation.dart';

part 'industry_track.freezed.dart';
part 'industry_track.g.dart';

@freezed
class IndustryTrack with _$IndustryTrack {
  const factory IndustryTrack({
    required int id,
    required String name,
    String? description,
  }) = _IndustryTrack;

  factory IndustryTrack.fromJson(Map<String, dynamic> json) =>
      _$IndustryTrackFromJson(json);
}
