import 'package:freezed_annotation/freezed_annotation.dart';

part 'industry_track.freezed.dart';
part 'industry_track.g.dart';

@freezed
class IndustryTrack with _$IndustryTrack {
  const factory IndustryTrack({
    required int id,
    required String name,
    String? description,
    /// Icon key the client maps to a glyph (e.g. `finance`, `legal`).
    /// Server-provided so new tracks need no client release; null falls back
    /// to a neutral icon.
    @JsonKey(name: 'icon_key') String? iconKey,
    /// One-line selling point shown under the track name.
    @JsonKey(name: 'perk') String? perk,
  }) = _IndustryTrack;

  factory IndustryTrack.fromJson(Map<String, dynamic> json) =>
      _$IndustryTrackFromJson(json);
}
