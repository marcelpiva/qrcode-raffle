// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RankingEntryModel _$RankingEntryModelFromJson(Map<String, dynamic> json) =>
    RankingEntryModel(
      email: json['email'] as String,
      normalizedEmail: json['normalizedEmail'] as String,
      participationCount: (json['participationCount'] as num).toInt(),
      wins: (json['wins'] as num).toInt(),
      names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toInt(),
      talksAttended: (json['talksAttended'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RankingEntryModelToJson(RankingEntryModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'normalizedEmail': instance.normalizedEmail,
      'participationCount': instance.participationCount,
      'wins': instance.wins,
      'names': instance.names,
      'totalDurationMinutes': instance.totalDurationMinutes,
      'talksAttended': instance.talksAttended,
    };

RankingResponse _$RankingResponseFromJson(Map<String, dynamic> json) =>
    RankingResponse(
      ranking: (json['ranking'] as List<dynamic>)
          .map((e) => RankingEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalParticipants: (json['totalParticipants'] as num).toInt(),
      filters: json['filters'] == null
          ? null
          : RankingFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RankingResponseToJson(RankingResponse instance) =>
    <String, dynamic>{
      'ranking': instance.ranking,
      'totalParticipants': instance.totalParticipants,
      'filters': instance.filters,
    };

RankingFilters _$RankingFiltersFromJson(Map<String, dynamic> json) =>
    RankingFilters(
      raffleIds: (json['raffleIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      eventIds: (json['eventIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trackIds: (json['trackIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minParticipations: (json['minParticipations'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RankingFiltersToJson(RankingFilters instance) =>
    <String, dynamic>{
      'raffleIds': instance.raffleIds,
      'eventIds': instance.eventIds,
      'trackIds': instance.trackIds,
      'minParticipations': instance.minParticipations,
    };

RaffleRankingRequest _$RaffleRankingRequestFromJson(
        Map<String, dynamic> json) =>
    RaffleRankingRequest(
      raffleIds:
          (json['raffleIds'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$RaffleRankingRequestToJson(
        RaffleRankingRequest instance) =>
    <String, dynamic>{
      'raffleIds': instance.raffleIds,
    };

EventRankingRequest _$EventRankingRequestFromJson(Map<String, dynamic> json) =>
    EventRankingRequest(
      eventIds:
          (json['eventIds'] as List<dynamic>).map((e) => e as String).toList(),
      minDurationMinutes: (json['minDurationMinutes'] as num?)?.toInt(),
      minTalksCount: (json['minTalksCount'] as num?)?.toInt(),
      allowedDomain: json['allowedDomain'] as String?,
    );

Map<String, dynamic> _$EventRankingRequestToJson(
        EventRankingRequest instance) =>
    <String, dynamic>{
      'eventIds': instance.eventIds,
      'minDurationMinutes': instance.minDurationMinutes,
      'minTalksCount': instance.minTalksCount,
      'allowedDomain': instance.allowedDomain,
    };

TrackRankingRequest _$TrackRankingRequestFromJson(Map<String, dynamic> json) =>
    TrackRankingRequest(
      trackIds:
          (json['trackIds'] as List<dynamic>).map((e) => e as String).toList(),
      minDurationMinutes: (json['minDurationMinutes'] as num?)?.toInt(),
      minTalksCount: (json['minTalksCount'] as num?)?.toInt(),
      allowedDomain: json['allowedDomain'] as String?,
    );

Map<String, dynamic> _$TrackRankingRequestToJson(
        TrackRankingRequest instance) =>
    <String, dynamic>{
      'trackIds': instance.trackIds,
      'minDurationMinutes': instance.minDurationMinutes,
      'minTalksCount': instance.minTalksCount,
      'allowedDomain': instance.allowedDomain,
    };

CreateVipRaffleRequest _$CreateVipRaffleRequestFromJson(
        Map<String, dynamic> json) =>
    CreateVipRaffleRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      prize: json['prize'] as String,
      raffleIds: (json['raffleIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      eventIds: (json['eventIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trackIds: (json['trackIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minParticipations: (json['minParticipations'] as num).toInt(),
      allowedDomain: json['allowedDomain'] as String?,
      requireConfirmation: json['requireConfirmation'] as bool? ?? false,
      confirmationTimeoutMinutes:
          (json['confirmationTimeoutMinutes'] as num?)?.toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
    );

Map<String, dynamic> _$CreateVipRaffleRequestToJson(
        CreateVipRaffleRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'prize': instance.prize,
      'raffleIds': instance.raffleIds,
      'eventIds': instance.eventIds,
      'trackIds': instance.trackIds,
      'minParticipations': instance.minParticipations,
      'allowedDomain': instance.allowedDomain,
      'requireConfirmation': instance.requireConfirmation,
      'confirmationTimeoutMinutes': instance.confirmationTimeoutMinutes,
      'startsAt': instance.startsAt?.toIso8601String(),
      'endsAt': instance.endsAt?.toIso8601String(),
    };

VipEligibleCountResponse _$VipEligibleCountResponseFromJson(
        Map<String, dynamic> json) =>
    VipEligibleCountResponse(
      count: (json['count'] as num).toInt(),
      minParticipations: (json['minParticipations'] as num).toInt(),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$VipEligibleCountResponseToJson(
        VipEligibleCountResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'minParticipations': instance.minParticipations,
      'source': instance.source,
    };
