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
  final DateTime? endsAt;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final String creatorId;
  final List<ParticipantModel>? participants;
  final ParticipantModel? winner;
  @JsonKey(name: '_count')
  final RaffleCount? count;

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
    this.endsAt,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    required this.creatorId,
    this.participants,
    this.winner,
    this.count,
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
      endsAt: endsAt,
      requireConfirmation: requireConfirmation,
      confirmationTimeoutMinutes: confirmationTimeoutMinutes,
      creatorId: creatorId,
      participants: participants?.map((p) => p.toEntity()).toList(),
      winner: winner?.toEntity(),
      participantCount: count?.participants,
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
      endsAt: raffle.endsAt,
      requireConfirmation: raffle.requireConfirmation,
      confirmationTimeoutMinutes: raffle.confirmationTimeoutMinutes,
      creatorId: raffle.creatorId,
      participants: raffle.participants
          ?.map((p) => ParticipantModel.fromEntity(p))
          .toList(),
      winner:
          raffle.winner != null ? ParticipantModel.fromEntity(raffle.winner!) : null,
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

  const CreateRaffleRequest({
    required this.name,
    this.description,
    required this.prize,
    this.allowedDomain,
    this.timeboxMinutes,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
  });

  factory CreateRaffleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRaffleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRaffleRequestToJson(this);
}

@JsonSerializable()
class UpdateRaffleRequest {
  final String? name;
  final String? description;
  final String? prize;
  final String? allowedDomain;
  final String? status;
  final int? timeboxMinutes;
  final bool? requireConfirmation;
  final int? confirmationTimeoutMinutes;

  const UpdateRaffleRequest({
    this.name,
    this.description,
    this.prize,
    this.allowedDomain,
    this.status,
    this.timeboxMinutes,
    this.requireConfirmation,
    this.confirmationTimeoutMinutes,
  });

  factory UpdateRaffleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRaffleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRaffleRequestToJson(this);
}

@JsonSerializable()
class DrawResultModel {
  final RaffleModel raffle;
  final ParticipantModel winner;
  final int drawNumber;

  const DrawResultModel({
    required this.raffle,
    required this.winner,
    required this.drawNumber,
  });

  factory DrawResultModel.fromJson(Map<String, dynamic> json) =>
      _$DrawResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$DrawResultModelToJson(this);
}
