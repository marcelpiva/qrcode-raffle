// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'talk_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TalkModel _$TalkModelFromJson(Map<String, dynamic> json) => TalkModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sem título',
      description: json['description'] as String?,
      speaker: json['speaker'] as String?,
      speakerEmail: json['speakerEmail'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      room: json['room'] as String?,
      trackId: json['trackId'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      attendances: (json['attendances'] as List<dynamic>?)
          ?.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendanceCount: (json['attendanceCount'] as num?)?.toInt(),
      raffleCount: (json['raffleCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TalkModelToJson(TalkModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'speaker': instance.speaker,
      'speakerEmail': instance.speakerEmail,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'room': instance.room,
      'trackId': instance.trackId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'attendances': instance.attendances,
      'attendanceCount': instance.attendanceCount,
      'raffleCount': instance.raffleCount,
    };

TalkCount _$TalkCountFromJson(Map<String, dynamic> json) => TalkCount(
      attendances: (json['attendances'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TalkCountToJson(TalkCount instance) => <String, dynamic>{
      'attendances': instance.attendances,
    };

CreateTalkRequest _$CreateTalkRequestFromJson(Map<String, dynamic> json) =>
    CreateTalkRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      speaker: json['speaker'] as String?,
      speakerEmail: json['speakerEmail'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      room: json['room'] as String?,
      trackId: json['trackId'] as String,
    );

Map<String, dynamic> _$CreateTalkRequestToJson(CreateTalkRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'speaker': instance.speaker,
      'speakerEmail': instance.speakerEmail,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'room': instance.room,
      'trackId': instance.trackId,
    };

UpdateTalkRequest _$UpdateTalkRequestFromJson(Map<String, dynamic> json) =>
    UpdateTalkRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      speaker: json['speaker'] as String?,
      speakerEmail: json['speakerEmail'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      room: json['room'] as String?,
    );

Map<String, dynamic> _$UpdateTalkRequestToJson(UpdateTalkRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'speaker': instance.speaker,
      'speakerEmail': instance.speakerEmail,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'room': instance.room,
    };
