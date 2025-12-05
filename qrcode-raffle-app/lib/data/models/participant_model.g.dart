// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantModel _$ParticipantModelFromJson(Map<String, dynamic> json) =>
    ParticipantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      raffleId: json['raffleId'] as String,
      hasPin: json['hasPin'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$ParticipantModelToJson(ParticipantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'raffleId': instance.raffleId,
      'hasPin': instance.hasPin,
      'createdAt': instance.createdAt.toIso8601String(),
      'userId': instance.userId,
    };

RegisterParticipantRequest _$RegisterParticipantRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterParticipantRequest(
      name: json['name'] as String,
      email: json['email'] as String,
      pin: json['pin'] as String?,
    );

Map<String, dynamic> _$RegisterParticipantRequestToJson(
        RegisterParticipantRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'pin': instance.pin,
    };

ConfirmPresenceRequest _$ConfirmPresenceRequestFromJson(
        Map<String, dynamic> json) =>
    ConfirmPresenceRequest(
      pin: json['pin'] as String,
    );

Map<String, dynamic> _$ConfirmPresenceRequestToJson(
        ConfirmPresenceRequest instance) =>
    <String, dynamic>{
      'pin': instance.pin,
    };

RegisterParticipantResponse _$RegisterParticipantResponseFromJson(
        Map<String, dynamic> json) =>
    RegisterParticipantResponse(
      participant: ParticipantModel.fromJson(
          json['participant'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$RegisterParticipantResponseToJson(
        RegisterParticipantResponse instance) =>
    <String, dynamic>{
      'participant': instance.participant,
      'message': instance.message,
    };
