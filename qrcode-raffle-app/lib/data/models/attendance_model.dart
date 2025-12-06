import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/attendance.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  final String id;
  final String email;
  final String? name;
  // talkId might be null when attendance is nested inside talk response
  @JsonKey(defaultValue: '')
  final String talkId;
  final int? durationMinutes;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.id,
    required this.email,
    this.name,
    required this.talkId,
    this.durationMinutes,
    this.checkinTime,
    this.checkoutTime,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);

  Attendance toEntity() {
    return Attendance(
      id: id,
      email: email,
      name: name,
      talkId: talkId,
      durationMinutes: durationMinutes,
      checkinTime: checkinTime,
      checkoutTime: checkoutTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@JsonSerializable()
class CreateAttendanceRequest {
  final String email;
  final String? name;
  final int? durationMinutes;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;

  const CreateAttendanceRequest({
    required this.email,
    this.name,
    this.durationMinutes,
    this.checkinTime,
    this.checkoutTime,
  });

  factory CreateAttendanceRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAttendanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAttendanceRequestToJson(this);
}

@JsonSerializable()
class BulkAttendanceRequest {
  final List<CreateAttendanceRequest> attendances;

  const BulkAttendanceRequest({required this.attendances});

  factory BulkAttendanceRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkAttendanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BulkAttendanceRequestToJson(this);
}
