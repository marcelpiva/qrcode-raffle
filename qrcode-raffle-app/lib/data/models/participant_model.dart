import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/participant.dart';

part 'participant_model.g.dart';

@JsonSerializable()
class ParticipantModel {
  final String id;
  final String name;
  final String email;
  final String raffleId;
  final bool? hasPin;
  final DateTime createdAt;
  final String? userId;

  const ParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.raffleId,
    this.hasPin,
    required this.createdAt,
    this.userId,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantModelToJson(this);

  Participant toEntity() {
    return Participant(
      id: id,
      name: name,
      email: email,
      raffleId: raffleId,
      hasPin: hasPin ?? false,
      createdAt: createdAt,
      userId: userId,
    );
  }

  factory ParticipantModel.fromEntity(Participant participant) {
    return ParticipantModel(
      id: participant.id,
      name: participant.name,
      email: participant.email,
      raffleId: participant.raffleId,
      hasPin: participant.hasPin,
      createdAt: participant.createdAt,
      userId: participant.userId,
    );
  }
}

@JsonSerializable()
class RegisterParticipantRequest {
  final String name;
  final String email;
  final String? pin;

  const RegisterParticipantRequest({
    required this.name,
    required this.email,
    this.pin,
  });

  factory RegisterParticipantRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterParticipantRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterParticipantRequestToJson(this);
}

@JsonSerializable()
class ConfirmPresenceRequest {
  final String pin;

  const ConfirmPresenceRequest({
    required this.pin,
  });

  factory ConfirmPresenceRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfirmPresenceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmPresenceRequestToJson(this);
}

@JsonSerializable()
class RegisterParticipantResponse {
  final ParticipantModel participant;
  final String message;

  const RegisterParticipantResponse({
    required this.participant,
    required this.message,
  });

  factory RegisterParticipantResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterParticipantResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterParticipantResponseToJson(this);
}
