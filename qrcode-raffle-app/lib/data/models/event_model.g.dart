// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      creatorId: json['creatorId'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      trackCount: (json['trackCount'] as num?)?.toInt(),
      raffleCount: (json['raffleCount'] as num?)?.toInt(),
      attendanceCount: (json['attendanceCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'location': instance.location,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'creatorId': instance.creatorId,
      'tracks': instance.tracks,
      'trackCount': instance.trackCount,
      'raffleCount': instance.raffleCount,
      'attendanceCount': instance.attendanceCount,
    };

EventCount _$EventCountFromJson(Map<String, dynamic> json) => EventCount(
      tracks: (json['tracks'] as num?)?.toInt(),
      talks: (json['talks'] as num?)?.toInt(),
      attendances: (json['attendances'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EventCountToJson(EventCount instance) =>
    <String, dynamic>{
      'tracks': instance.tracks,
      'talks': instance.talks,
      'attendances': instance.attendances,
    };

CreateEventRequest _$CreateEventRequestFromJson(Map<String, dynamic> json) =>
    CreateEventRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$CreateEventRequestToJson(CreateEventRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'location': instance.location,
      'imageUrl': instance.imageUrl,
    };

UpdateEventRequest _$UpdateEventRequestFromJson(Map<String, dynamic> json) =>
    UpdateEventRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$UpdateEventRequestToJson(UpdateEventRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'location': instance.location,
      'imageUrl': instance.imageUrl,
    };

EligibleCountResponse _$EligibleCountResponseFromJson(
        Map<String, dynamic> json) =>
    EligibleCountResponse(
      count: (json['eligibleCount'] as num?)?.toInt() ?? 0,
      eventId: json['eventId'] as String?,
      minDurationMinutes: (json['minDurationMinutes'] as num?)?.toInt(),
      minTalksCount: (json['minTalksCount'] as num?)?.toInt(),
      allowedDomain: json['allowedDomain'] as String?,
    );

Map<String, dynamic> _$EligibleCountResponseToJson(
        EligibleCountResponse instance) =>
    <String, dynamic>{
      'eligibleCount': instance.count,
      'eventId': instance.eventId,
      'minDurationMinutes': instance.minDurationMinutes,
      'minTalksCount': instance.minTalksCount,
      'allowedDomain': instance.allowedDomain,
    };
