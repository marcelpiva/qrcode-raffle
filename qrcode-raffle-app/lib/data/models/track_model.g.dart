// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackModel _$TrackModelFromJson(Map<String, dynamic> json) => TrackModel(
      id: json['id'] as String,
      name: json['title'] as String? ?? 'Sem nome',
      description: json['description'] as String?,
      color: json['color'] as String?,
      eventId: json['eventId'] as String? ?? '',
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      talks: (json['talks'] as List<dynamic>?)
          ?.map((e) => TalkModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      talkCount: (json['talkCount'] as num?)?.toInt(),
      attendanceCount: (json['attendanceCount'] as num?)?.toInt(),
      raffleCount: (json['raffleCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TrackModelToJson(TrackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.name,
      'description': instance.description,
      'color': instance.color,
      'eventId': instance.eventId,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'talks': instance.talks,
      'talkCount': instance.talkCount,
      'attendanceCount': instance.attendanceCount,
      'raffleCount': instance.raffleCount,
    };

TrackCount _$TrackCountFromJson(Map<String, dynamic> json) => TrackCount(
      talks: (json['talks'] as num?)?.toInt(),
      attendances: (json['attendances'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TrackCountToJson(TrackCount instance) =>
    <String, dynamic>{
      'talks': instance.talks,
      'attendances': instance.attendances,
    };

CreateTrackRequest _$CreateTrackRequestFromJson(Map<String, dynamic> json) =>
    CreateTrackRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      eventId: json['eventId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$CreateTrackRequestToJson(CreateTrackRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'color': instance.color,
      'eventId': instance.eventId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };

UpdateTrackRequest _$UpdateTrackRequestFromJson(Map<String, dynamic> json) =>
    UpdateTrackRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$UpdateTrackRequestToJson(UpdateTrackRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'color': instance.color,
    };
