import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/raffle.dart';
import 'participant_model.dart';

part 'raffle_model.g.dart';

@JsonSerializable()
class RaffleModel {
  final String id;
  final String name;
  final String? description;
  final String prize;
  final String? allowedDomain;
  final String status;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int? timeboxMinutes;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final String? creatorId;
  final List<ParticipantModel>? participants;
  final ParticipantModel? winner;
  @JsonKey(name: '_count')
  final RaffleCount? count;
  // Event-related fields
  final String? eventId;
  final String? talkId;
  final bool autoDrawOnEnd;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final bool allowLinkRegistration;

  const RaffleModel({
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
    this.count,
    this.eventId,
    this.talkId,
    this.autoDrawOnEnd = false,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowLinkRegistration = true,
  });

  factory RaffleModel.fromJson(Map<String, dynamic> json) =>
      _$RaffleModelFromJson(json);

  Map<String, dynamic> toJson() => _$RaffleModelToJson(this);

  Raffle toEntity() {
    return Raffle(
      id: id,
      name: name,
      description: description,
      prize: prize,
      allowedDomain: allowedDomain,
      status: _parseStatus(status),
      winnerId: winnerId,
      createdAt: createdAt,
      closedAt: closedAt,
      timeboxMinutes: timeboxMinutes,
      startsAt: startsAt,
      endsAt: endsAt,
      requireConfirmation: requireConfirmation,
      confirmationTimeoutMinutes: confirmationTimeoutMinutes,
      creatorId: creatorId,
      participants: participants?.map((p) => p.toEntity()).toList(),
      winner: winner?.toEntity(),
      participantCount: count?.participants,
      eventId: eventId,
      talkId: talkId,
      autoDrawOnEnd: autoDrawOnEnd,
      minDurationMinutes: minDurationMinutes,
      minTalksCount: minTalksCount,
      allowLinkRegistration: allowLinkRegistration,
    );
  }

  factory RaffleModel.fromEntity(Raffle raffle) {
    return RaffleModel(
      id: raffle.id,
      name: raffle.name,
      description: raffle.description,
      prize: raffle.prize,
      allowedDomain: raffle.allowedDomain,
      status: raffle.status.name.toUpperCase(),
      winnerId: raffle.winnerId,
      createdAt: raffle.createdAt,
      closedAt: raffle.closedAt,
      timeboxMinutes: raffle.timeboxMinutes,
      startsAt: raffle.startsAt,
      endsAt: raffle.endsAt,
      requireConfirmation: raffle.requireConfirmation,
      confirmationTimeoutMinutes: raffle.confirmationTimeoutMinutes,
      creatorId: raffle.creatorId,
      participants: raffle.participants
          ?.map((p) => ParticipantModel.fromEntity(p))
          .toList(),
      winner:
          raffle.winner != null ? ParticipantModel.fromEntity(raffle.winner!) : null,
      eventId: raffle.eventId,
      talkId: raffle.talkId,
      autoDrawOnEnd: raffle.autoDrawOnEnd,
      minDurationMinutes: raffle.minDurationMinutes,
      minTalksCount: raffle.minTalksCount,
      allowLinkRegistration: raffle.allowLinkRegistration,
    );
  }

  static RaffleStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return RaffleStatus.active;
      case 'CLOSED':
        return RaffleStatus.closed;
      case 'DRAWN':
        return RaffleStatus.drawn;
      default:
        return RaffleStatus.active;
    }
  }
}

@JsonSerializable()
class RaffleCount {
  final int? participants;

  const RaffleCount({this.participants});

  factory RaffleCount.fromJson(Map<String, dynamic> json) =>
      _$RaffleCountFromJson(json);

  Map<String, dynamic> toJson() => _$RaffleCountToJson(this);
}

@JsonSerializable()
class CreateRaffleRequest {
  final String name;
  final String? description;
  final String prize;
  final String? allowedDomain;
  final int? timeboxMinutes;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  // Schedule fields
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool autoDrawOnEnd;
  // Event/Talk fields
  final String? eventId;
  final String? talkId;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final bool allowLinkRegistration;

  const CreateRaffleRequest({
    required this.name,
    this.description,
    required this.prize,
    this.allowedDomain,
    this.timeboxMinutes,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    this.startsAt,
    this.endsAt,
    this.autoDrawOnEnd = false,
    this.eventId,
    this.talkId,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowLinkRegistration = true,
  });

  factory CreateRaffleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRaffleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRaffleRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class UpdateRaffleRequest {
  final String? name;
  final String? description;
  final String? prize;
  final String? allowedDomain;
  final String? status;
  final int? timeboxMinutes;
  final bool? requireConfirmation;
  final int? confirmationTimeoutMinutes;
  // Event-related toggles
  final bool? allowLinkRegistration;
  final bool? autoDrawOnEnd;

  const UpdateRaffleRequest({
    this.name,
    this.description,
    this.prize,
    this.allowedDomain,
    this.status,
    this.timeboxMinutes,
    this.requireConfirmation,
    this.confirmationTimeoutMinutes,
    this.allowLinkRegistration,
    this.autoDrawOnEnd,
  });

  factory UpdateRaffleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRaffleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRaffleRequestToJson(this);
}

@JsonSerializable()
class DrawResultModel {
  final RaffleModel raffle;
  final ParticipantModel winner;
  final int? drawNumber;

  const DrawResultModel({
    required this.raffle,
    required this.winner,
    this.drawNumber,
  });

  factory DrawResultModel.fromJson(Map<String, dynamic> json) =>
      _$DrawResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$DrawResultModelToJson(this);
}
