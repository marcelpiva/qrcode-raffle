import 'package:equatable/equatable.dart';
import 'participant.dart';

enum RaffleStatus {
  active,
  closed,
  drawn;

  String get displayName {
    switch (this) {
      case RaffleStatus.active:
        return 'Ativo';
      case RaffleStatus.closed:
        return 'Fechado';
      case RaffleStatus.drawn:
        return 'Sorteado';
    }
  }

  String get description {
    switch (this) {
      case RaffleStatus.active:
        return 'Aceitando participantes';
      case RaffleStatus.closed:
        return 'Inscrições encerradas';
      case RaffleStatus.drawn:
        return 'Sorteio realizado';
    }
  }
}

class Raffle extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String prize;
  final String? allowedDomain;
  final RaffleStatus status;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int? timeboxMinutes;
  final DateTime? endsAt;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final String creatorId;
  final List<Participant>? participants;
  final Participant? winner;
  final int? participantCount;

  const Raffle({
    required this.id,
    required this.name,
    this.description,
    required this.prize,
    this.allowedDomain,
    required this.status,
    this.winnerId,
    required this.createdAt,
    this.closedAt,
    this.timeboxMinutes,
    this.endsAt,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    required this.creatorId,
    this.participants,
    this.winner,
    this.participantCount,
  });

  bool get isActive => status == RaffleStatus.active;
  bool get isClosed => status == RaffleStatus.closed;
  bool get isDrawn => status == RaffleStatus.drawn;
  bool get hasWinner => winnerId != null;
  bool get hasTimebox => timeboxMinutes != null && endsAt != null;

  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  Duration? get remainingTime {
    if (endsAt == null) return null;
    final remaining = endsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get totalParticipants =>
      participantCount ?? participants?.length ?? 0;

  Raffle copyWith({
    String? id,
    String? name,
    String? description,
    String? prize,
    String? allowedDomain,
    RaffleStatus? status,
    String? winnerId,
    DateTime? createdAt,
    DateTime? closedAt,
    int? timeboxMinutes,
    DateTime? endsAt,
    bool? requireConfirmation,
    int? confirmationTimeoutMinutes,
    String? creatorId,
    List<Participant>? participants,
    Participant? winner,
    int? participantCount,
  }) {
    return Raffle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prize: prize ?? this.prize,
      allowedDomain: allowedDomain ?? this.allowedDomain,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      timeboxMinutes: timeboxMinutes ?? this.timeboxMinutes,
      endsAt: endsAt ?? this.endsAt,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      confirmationTimeoutMinutes:
          confirmationTimeoutMinutes ?? this.confirmationTimeoutMinutes,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      winner: winner ?? this.winner,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        prize,
        allowedDomain,
        status,
        winnerId,
        createdAt,
        closedAt,
        timeboxMinutes,
        endsAt,
        requireConfirmation,
        confirmationTimeoutMinutes,
        creatorId,
        participants,
        winner,
        participantCount,
      ];
}
