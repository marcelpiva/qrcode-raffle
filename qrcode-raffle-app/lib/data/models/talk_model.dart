import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/talk.dart';
import 'attendance_model.dart';

part 'talk_model.g.dart';

@JsonSerializable()
class TalkModel {
  final String id;
  @JsonKey(defaultValue: 'Sem título')
  final String title;
  final String? description;
  final String? speaker;
  final String? speakerEmail;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? room;
  // trackId might be null when talk is nested inside track response
  @JsonKey(defaultValue: '')
  final String trackId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AttendanceModel>? attendances;
  // API returns these directly, not inside _count
  final int? attendanceCount;
  final int? raffleCount;

  const TalkModel({
    required this.id,
    required this.title,
    this.description,
    this.speaker,
    this.speakerEmail,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.room,
    required this.trackId,
    this.createdAt,
    this.updatedAt,
    this.attendances,
    this.attendanceCount,
    this.raffleCount,
  });

  factory TalkModel.fromJson(Map<String, dynamic> json) =>
      _$TalkModelFromJson(json);

  Map<String, dynamic> toJson() => _$TalkModelToJson(this);

  Talk toEntity() {
    return Talk(
      id: id,
      title: title,
      description: description,
      speaker: speaker,
      speakerEmail: speakerEmail,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      room: room,
      trackId: trackId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      attendances: attendances?.map((a) => a.toEntity()).toList(),
      attendanceCount: attendanceCount,
    );
  }
}

@JsonSerializable()
class TalkCount {
  final int? attendances;

  const TalkCount({this.attendances});

  factory TalkCount.fromJson(Map<String, dynamic> json) =>
      _$TalkCountFromJson(json);

  Map<String, dynamic> toJson() => _$TalkCountToJson(this);
}

@JsonSerializable()
class CreateTalkRequest {
  final String title;
  final String? description;
  final String? speaker;
  final String? speakerEmail;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? room;
  final String trackId;

  const CreateTalkRequest({
    required this.title,
    this.description,
    this.speaker,
    this.speakerEmail,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.room,
    required this.trackId,
  });

  factory CreateTalkRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTalkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTalkRequestToJson(this);
}

@JsonSerializable()
class UpdateTalkRequest {
  final String? title;
  final String? description;
  final String? speaker;
  final String? speakerEmail;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? room;

  const UpdateTalkRequest({
    this.title,
    this.description,
    this.speaker,
    this.speakerEmail,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.room,
  });

  factory UpdateTalkRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTalkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTalkRequestToJson(this);
}
