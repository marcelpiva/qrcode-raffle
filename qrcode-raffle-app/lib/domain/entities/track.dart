import 'package:equatable/equatable.dart';
import 'talk.dart';

class Track extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String eventId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Talk>? talks;
  final int? talkCount;
  final int? attendanceCount;

  const Track({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.eventId,
    this.createdAt,
    this.updatedAt,
    this.talks,
    this.talkCount,
    this.attendanceCount,
  });

  int get totalTalks => talkCount ?? talks?.length ?? 0;
  int get totalAttendances => attendanceCount ?? 0;

  Track copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? eventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Talk>? talks,
    int? talkCount,
    int? attendanceCount,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      talks: talks ?? this.talks,
      talkCount: talkCount ?? this.talkCount,
      attendanceCount: attendanceCount ?? this.attendanceCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        eventId,
        createdAt,
        updatedAt,
        talks,
        talkCount,
        attendanceCount,
      ];
}
