import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String talkId;
  final int? durationMinutes;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Attendance({
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

  String get formattedDuration {
    if (durationMinutes == null) return '';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}';
    }
    return '${minutes}min';
  }

  String get displayName => name ?? email.split('@').first;

  Attendance copyWith({
    String? id,
    String? email,
    String? name,
    String? talkId,
    int? durationMinutes,
    DateTime? checkinTime,
    DateTime? checkoutTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      talkId: talkId ?? this.talkId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      checkinTime: checkinTime ?? this.checkinTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        talkId,
        durationMinutes,
        checkinTime,
        checkoutTime,
        createdAt,
        updatedAt,
      ];
}
