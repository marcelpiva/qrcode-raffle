import 'package:equatable/equatable.dart';
import 'participant.dart';

class DrawHistory extends Equatable {
  final String id;
  final String raffleId;
  final String participantId;
  final int drawNumber;
  final bool wasPresent;
  final DateTime createdAt;
  final Participant? participant;

  const DrawHistory({
    required this.id,
    required this.raffleId,
    required this.participantId,
    required this.drawNumber,
    required this.wasPresent,
    required this.createdAt,
    this.participant,
  });

  DrawHistory copyWith({
    String? id,
    String? raffleId,
    String? participantId,
    int? drawNumber,
    bool? wasPresent,
    DateTime? createdAt,
    Participant? participant,
  }) {
    return DrawHistory(
      id: id ?? this.id,
      raffleId: raffleId ?? this.raffleId,
      participantId: participantId ?? this.participantId,
      drawNumber: drawNumber ?? this.drawNumber,
      wasPresent: wasPresent ?? this.wasPresent,
      createdAt: createdAt ?? this.createdAt,
      participant: participant ?? this.participant,
    );
  }

  @override
  List<Object?> get props => [
        id,
        raffleId,
        participantId,
        drawNumber,
        wasPresent,
        createdAt,
        participant,
      ];
}
