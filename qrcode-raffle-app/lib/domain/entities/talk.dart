import 'package:equatable/equatable.dart';
import 'attendance.dart';

class Talk extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? speaker;
  final String? speakerEmail;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? room;
  final String trackId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Attendance>? attendances;
  final int? attendanceCount;

  const Talk({
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
  });

  bool get isOngoing {
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  bool get hasStarted {
    if (startTime == null) return true;
    return DateTime.now().isAfter(startTime!);
  }

  bool get hasEnded {
    if (endTime == null) return false;
    return DateTime.now().isAfter(endTime!);
  }

  int get totalAttendances => attendanceCount ?? attendances?.length ?? 0;

  String get formattedDuration {
    if (durationMinutes == null) return '';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}';
    }
    return '${minutes}min';
  }

  Talk copyWith({
    String? id,
    String? title,
    String? description,
    String? speaker,
    String? speakerEmail,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? room,
    String? trackId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Attendance>? attendances,
    int? attendanceCount,
  }) {
    return Talk(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      speaker: speaker ?? this.speaker,
      speakerEmail: speakerEmail ?? this.speakerEmail,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      room: room ?? this.room,
      trackId: trackId ?? this.trackId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendances: attendances ?? this.attendances,
      attendanceCount: attendanceCount ?? this.attendanceCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        speaker,
        speakerEmail,
        startTime,
        endTime,
        durationMinutes,
        room,
        trackId,
        createdAt,
        updatedAt,
        attendances,
        attendanceCount,
      ];
}
