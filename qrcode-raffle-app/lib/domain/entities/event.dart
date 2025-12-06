import 'package:equatable/equatable.dart';
import 'track.dart';

class Event extends Equatable {
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
  final List<Track>? tracks;
  final int? trackCount;
  final int? talkCount;
  final int? attendanceCount;

  const Event({
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
    this.talkCount,
    this.attendanceCount,
  });

  bool get isOngoing {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  bool get hasStarted {
    if (startDate == null) return true;
    return DateTime.now().isAfter(startDate!);
  }

  bool get hasEnded {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  int get totalTracks => trackCount ?? tracks?.length ?? 0;
  int get totalTalks => talkCount ?? 0;
  int get totalAttendances => attendanceCount ?? 0;

  Event copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorId,
    List<Track>? tracks,
    int? trackCount,
    int? talkCount,
    int? attendanceCount,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorId: creatorId ?? this.creatorId,
      tracks: tracks ?? this.tracks,
      trackCount: trackCount ?? this.trackCount,
      talkCount: talkCount ?? this.talkCount,
      attendanceCount: attendanceCount ?? this.attendanceCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        startDate,
        endDate,
        location,
        imageUrl,
        createdAt,
        updatedAt,
        creatorId,
        tracks,
        trackCount,
        talkCount,
        attendanceCount,
      ];
}
