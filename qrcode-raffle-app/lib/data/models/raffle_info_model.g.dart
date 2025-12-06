// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raffle_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaffleInfoModel _$RaffleInfoModelFromJson(Map<String, dynamic> json) =>
    RaffleInfoModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      prize: json['prize'] as String,
      status: json['status'] as String,
      allowedDomain: json['allowedDomain'] as String?,
      participantCount: (json['participantCount'] as num).toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      requireConfirmation: json['requireConfirmation'] as bool? ?? false,
      eventId: json['eventId'] as String?,
      talkId: json['talkId'] as String?,
      allowLinkRegistration: json['allowLinkRegistration'] as bool? ?? true,
    );

Map<String, dynamic> _$RaffleInfoModelToJson(RaffleInfoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'prize': instance.prize,
      'status': instance.status,
      'allowedDomain': instance.allowedDomain,
      'participantCount': instance.participantCount,
      'startsAt': instance.startsAt?.toIso8601String(),
      'endsAt': instance.endsAt?.toIso8601String(),
      'requireConfirmation': instance.requireConfirmation,
      'eventId': instance.eventId,
      'talkId': instance.talkId,
      'allowLinkRegistration': instance.allowLinkRegistration,
    };
