import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/track.dart';
import 'talk_model.dart';

part 'track_model.g.dart';

@JsonSerializable()
class TrackModel {
  final String id;
  // API returns 'title', map to name for entity
  // Use readValue to handle null title gracefully
  @JsonKey(name: 'title', defaultValue: 'Sem nome')
  final String name;
  final String? description;
  final String? color;
  // eventId might be null when track is nested inside event response
  @JsonKey(defaultValue: '')
  final String eventId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TalkModel>? talks;
  // API returns these directly, not inside _count
  final int? talkCount;
  final int? attendanceCount;
  final int? raffleCount;

  const TrackModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.eventId,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.talks,
    this.talkCount,
    this.attendanceCount,
    this.raffleCount,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) =>
      _$TrackModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrackModelToJson(this);

  Track toEntity() {
    return Track(
      id: id,
      name: name,
      description: description,
      color: color,
      eventId: eventId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      talks: talks?.map((t) => t.toEntity()).toList(),
      talkCount: talkCount,
      attendanceCount: attendanceCount,
    );
  }
}

@JsonSerializable()
class TrackCount {
  final int? talks;
  final int? attendances;

  const TrackCount({
    this.talks,
    this.attendances,
  });

  factory TrackCount.fromJson(Map<String, dynamic> json) =>
      _$TrackCountFromJson(json);

  Map<String, dynamic> toJson() => _$TrackCountToJson(this);
}

@JsonSerializable()
class CreateTrackRequest {
  final String title;
  final String? description;
  final String? color;
  final String eventId;
  final DateTime startDate;
  final DateTime endDate;

  const CreateTrackRequest({
    required this.title,
    this.description,
    this.color,
    required this.eventId,
    required this.startDate,
    required this.endDate,
  });

  factory CreateTrackRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTrackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTrackRequestToJson(this);
}

@JsonSerializable()
class UpdateTrackRequest {
  final String? name;
  final String? description;
  final String? color;

  const UpdateTrackRequest({
    this.name,
    this.description,
    this.color,
  });

  factory UpdateTrackRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTrackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTrackRequestToJson(this);
}
