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
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final String? creatorId;
  final List<Participant>? participants;
  final Participant? winner;
  final int? participantCount;
  // Event-related fields
  final String? eventId;
  final String? talkId;
  final bool autoDrawOnEnd;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final bool allowLinkRegistration;

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
    this.startsAt,
    this.endsAt,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    this.creatorId,
    this.participants,
    this.winner,
    this.participantCount,
    this.eventId,
    this.talkId,
    this.autoDrawOnEnd = false,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowLinkRegistration = true,
  });

  bool get isActive => status == RaffleStatus.active;
  bool get isClosed => status == RaffleStatus.closed;
  bool get isDrawn => status == RaffleStatus.drawn;
  bool get hasWinner => winnerId != null;
  bool get hasTimebox => timeboxMinutes != null && endsAt != null;
  bool get hasSchedule => startsAt != null || endsAt != null;
  bool get isEventRaffle => eventId != null && talkId == null;
  bool get isTalkRaffle => talkId != null;

  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  bool get hasNotStarted {
    if (startsAt == null) return false;
    return DateTime.now().isBefore(startsAt!);
  }

  bool get isOpen {
    if (status != RaffleStatus.active) return false;
    if (hasNotStarted) return false;
    if (isExpired) return false;
    return true;
  }

  Duration? get remainingTime {
    if (endsAt == null) return null;
    final remaining = endsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration? get timeUntilStart {
    if (startsAt == null) return null;
    final remaining = startsAt!.difference(DateTime.now());
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
    DateTime? startsAt,
    DateTime? endsAt,
    bool? requireConfirmation,
    int? confirmationTimeoutMinutes,
    String? creatorId,
    List<Participant>? participants,
    Participant? winner,
    int? participantCount,
    String? eventId,
    String? talkId,
    bool? autoDrawOnEnd,
    int? minDurationMinutes,
    int? minTalksCount,
    bool? allowLinkRegistration,
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
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      confirmationTimeoutMinutes:
          confirmationTimeoutMinutes ?? this.confirmationTimeoutMinutes,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      winner: winner ?? this.winner,
      participantCount: participantCount ?? this.participantCount,
      eventId: eventId ?? this.eventId,
      talkId: talkId ?? this.talkId,
      autoDrawOnEnd: autoDrawOnEnd ?? this.autoDrawOnEnd,
      minDurationMinutes: minDurationMinutes ?? this.minDurationMinutes,
      minTalksCount: minTalksCount ?? this.minTalksCount,
      allowLinkRegistration:
          allowLinkRegistration ?? this.allowLinkRegistration,
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
        startsAt,
        endsAt,
        requireConfirmation,
        confirmationTimeoutMinutes,
        creatorId,
        participants,
        winner,
        participantCount,
        eventId,
        talkId,
        autoDrawOnEnd,
        minDurationMinutes,
        minTalksCount,
        allowLinkRegistration,
      ];
}
