// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      talkId: json['talkId'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      checkinTime: json['checkinTime'] == null
          ? null
          : DateTime.parse(json['checkinTime'] as String),
      checkoutTime: json['checkoutTime'] == null
          ? null
          : DateTime.parse(json['checkoutTime'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AttendanceModelToJson(AttendanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'talkId': instance.talkId,
      'durationMinutes': instance.durationMinutes,
      'checkinTime': instance.checkinTime?.toIso8601String(),
      'checkoutTime': instance.checkoutTime?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

CreateAttendanceRequest _$CreateAttendanceRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAttendanceRequest(
      email: json['email'] as String,
      name: json['name'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      checkinTime: json['checkinTime'] == null
          ? null
          : DateTime.parse(json['checkinTime'] as String),
      checkoutTime: json['checkoutTime'] == null
          ? null
          : DateTime.parse(json['checkoutTime'] as String),
    );

Map<String, dynamic> _$CreateAttendanceRequestToJson(
        CreateAttendanceRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'durationMinutes': instance.durationMinutes,
      'checkinTime': instance.checkinTime?.toIso8601String(),
      'checkoutTime': instance.checkoutTime?.toIso8601String(),
    };

BulkAttendanceRequest _$BulkAttendanceRequestFromJson(
        Map<String, dynamic> json) =>
    BulkAttendanceRequest(
      attendances: (json['attendances'] as List<dynamic>)
          .map((e) =>
              CreateAttendanceRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BulkAttendanceRequestToJson(
        BulkAttendanceRequest instance) =>
    <String, dynamic>{
      'attendances': instance.attendances,
    };
