// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raffle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaffleModel _$RaffleModelFromJson(Map<String, dynamic> json) => RaffleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      prize: json['prize'] as String,
      allowedDomain: json['allowedDomain'] as String?,
      status: json['status'] as String,
      winnerId: json['winnerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      timeboxMinutes: (json['timeboxMinutes'] as num?)?.toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      requireConfirmation: json['requireConfirmation'] as bool? ?? false,
      confirmationTimeoutMinutes:
          (json['confirmationTimeoutMinutes'] as num?)?.toInt(),
      creatorId: json['creatorId'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      winner: json['winner'] == null
          ? null
          : ParticipantModel.fromJson(json['winner'] as Map<String, dynamic>),
      count: json['_count'] == null
          ? null
          : RaffleCount.fromJson(json['_count'] as Map<String, dynamic>),
      eventId: json['eventId'] as String?,
      talkId: json['talkId'] as String?,
      autoDrawOnEnd: json['autoDrawOnEnd'] as bool? ?? false,
      minDurationMinutes: (json['minDurationMinutes'] as num?)?.toInt(),
      minTalksCount: (json['minTalksCount'] as num?)?.toInt(),
      allowLinkRegistration: json['allowLinkRegistration'] as bool? ?? true,
    );

Map<String, dynamic> _$RaffleModelToJson(RaffleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'prize': instance.prize,
      'allowedDomain': instance.allowedDomain,
      'status': instance.status,
      'winnerId': instance.winnerId,
      'createdAt': instance.createdAt.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
      'timeboxMinutes': instance.timeboxMinutes,
      'startsAt': instance.startsAt?.toIso8601String(),
      'endsAt': instance.endsAt?.toIso8601String(),
      'requireConfirmation': instance.requireConfirmation,
      'confirmationTimeoutMinutes': instance.confirmationTimeoutMinutes,
      'creatorId': instance.creatorId,
      'participants': instance.participants,
      'winner': instance.winner,
      '_count': instance.count,
      'eventId': instance.eventId,
      'talkId': instance.talkId,
      'autoDrawOnEnd': instance.autoDrawOnEnd,
      'minDurationMinutes': instance.minDurationMinutes,
      'minTalksCount': instance.minTalksCount,
      'allowLinkRegistration': instance.allowLinkRegistration,
    };

RaffleCount _$RaffleCountFromJson(Map<String, dynamic> json) => RaffleCount(
      participants: (json['participants'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaffleCountToJson(RaffleCount instance) =>
    <String, dynamic>{
      'participants': instance.participants,
    };

CreateRaffleRequest _$CreateRaffleRequestFromJson(Map<String, dynamic> json) =>
    CreateRaffleRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      prize: json['prize'] as String,
      allowedDomain: json['allowedDomain'] as String?,
      timeboxMinutes: (json['timeboxMinutes'] as num?)?.toInt(),
      requireConfirmation: json['requireConfirmation'] as bool? ?? false,
      confirmationTimeoutMinutes:
          (json['confirmationTimeoutMinutes'] as num?)?.toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      autoDrawOnEnd: json['autoDrawOnEnd'] as bool? ?? false,
      eventId: json['eventId'] as String?,
      talkId: json['talkId'] as String?,
      minDurationMinutes: (json['minDurationMinutes'] as num?)?.toInt(),
      minTalksCount: (json['minTalksCount'] as num?)?.toInt(),
      allowLinkRegistration: json['allowLinkRegistration'] as bool? ?? true,
    );

Map<String, dynamic> _$CreateRaffleRequestToJson(
        CreateRaffleRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'prize': instance.prize,
      'allowedDomain': instance.allowedDomain,
      'timeboxMinutes': instance.timeboxMinutes,
      'requireConfirmation': instance.requireConfirmation,
      'confirmationTimeoutMinutes': instance.confirmationTimeoutMinutes,
      'startsAt': instance.startsAt?.toIso8601String(),
      'endsAt': instance.endsAt?.toIso8601String(),
      'autoDrawOnEnd': instance.autoDrawOnEnd,
      'eventId': instance.eventId,
      'talkId': instance.talkId,
      'minDurationMinutes': instance.minDurationMinutes,
      'minTalksCount': instance.minTalksCount,
      'allowLinkRegistration': instance.allowLinkRegistration,
    };

UpdateRaffleRequest _$UpdateRaffleRequestFromJson(Map<String, dynamic> json) =>
    UpdateRaffleRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      prize: json['prize'] as String?,
      allowedDomain: json['allowedDomain'] as String?,
      status: json['status'] as String?,
      timeboxMinutes: (json['timeboxMinutes'] as num?)?.toInt(),
      requireConfirmation: json['requireConfirmation'] as bool?,
      confirmationTimeoutMinutes:
          (json['confirmationTimeoutMinutes'] as num?)?.toInt(),
      allowLinkRegistration: json['allowLinkRegistration'] as bool?,
      autoDrawOnEnd: json['autoDrawOnEnd'] as bool?,
    );

Map<String, dynamic> _$UpdateRaffleRequestToJson(UpdateRaffleRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('prize', instance.prize);
  writeNotNull('allowedDomain', instance.allowedDomain);
  writeNotNull('status', instance.status);
  writeNotNull('timeboxMinutes', instance.timeboxMinutes);
  writeNotNull('requireConfirmation', instance.requireConfirmation);
  writeNotNull(
      'confirmationTimeoutMinutes', instance.confirmationTimeoutMinutes);
  writeNotNull('allowLinkRegistration', instance.allowLinkRegistration);
  writeNotNull('autoDrawOnEnd', instance.autoDrawOnEnd);
  return val;
}

DrawResultModel _$DrawResultModelFromJson(Map<String, dynamic> json) =>
    DrawResultModel(
      raffle: RaffleModel.fromJson(json['raffle'] as Map<String, dynamic>),
      winner: ParticipantModel.fromJson(json['winner'] as Map<String, dynamic>),
      drawNumber: (json['drawNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DrawResultModelToJson(DrawResultModel instance) =>
    <String, dynamic>{
      'raffle': instance.raffle,
      'winner': instance.winner,
      'drawNumber': instance.drawNumber,
    };
