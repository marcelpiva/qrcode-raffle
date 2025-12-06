import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/event.dart';
import 'track_model.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? creatorId;
  final List<TrackModel>? tracks;
  // API returns these directly, not inside _count
  final int? trackCount;
  final int? raffleCount;
  final int? attendanceCount;

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.creatorId,
    this.tracks,
    this.trackCount,
    this.raffleCount,
    this.attendanceCount,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  Event toEntity() {
    return Event(
      id: id,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      creatorId: creatorId,
      tracks: tracks?.map((t) => t.toEntity()).toList(),
      trackCount: trackCount,
      talkCount: tracks?.fold<int>(0, (sum, t) => sum + (t.talkCount ?? 0)),
      attendanceCount: attendanceCount,
    );
  }
}

@JsonSerializable()
class EventCount {
  final int? tracks;
  final int? talks;
  final int? attendances;

  const EventCount({
    this.tracks,
    this.talks,
    this.attendances,
  });

  factory EventCount.fromJson(Map<String, dynamic> json) =>
      _$EventCountFromJson(json);

  Map<String, dynamic> toJson() => _$EventCountToJson(this);
}

@JsonSerializable()
class CreateEventRequest {
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? imageUrl;

  const CreateEventRequest({
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.imageUrl,
  });

  factory CreateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEventRequestToJson(this);
}

@JsonSerializable()
class UpdateEventRequest {
  final String? name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? imageUrl;

  const UpdateEventRequest({
    this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.imageUrl,
  });

  factory UpdateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateEventRequestToJson(this);
}

@JsonSerializable()
class EligibleCountResponse {
  @JsonKey(name: 'eligibleCount', defaultValue: 0)
  final int count;
  final String? eventId;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final String? allowedDomain;

  const EligibleCountResponse({
    required this.count,
    this.eventId,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowedDomain,
  });

  factory EligibleCountResponse.fromJson(Map<String, dynamic> json) =>
      _$EligibleCountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EligibleCountResponseToJson(this);
}
