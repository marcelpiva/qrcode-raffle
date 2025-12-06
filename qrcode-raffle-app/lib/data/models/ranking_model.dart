import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ranking_entry.dart';

part 'ranking_model.g.dart';

@JsonSerializable()
class RankingEntryModel {
  final String email;
  final String normalizedEmail;
  final int participationCount;
  final int wins;
  final List<String> names;
  final int? totalDurationMinutes;
  final int? talksAttended;

  const RankingEntryModel({
    required this.email,
    required this.normalizedEmail,
    required this.participationCount,
    required this.wins,
    required this.names,
    this.totalDurationMinutes,
    this.talksAttended,
  });

  factory RankingEntryModel.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$RankingEntryModelToJson(this);

  RankingEntry toEntity(int position) {
    return RankingEntry(
      email: email,
      normalizedEmail: normalizedEmail,
      participationCount: participationCount,
      wins: wins,
      names: names,
      position: position,
    );
  }
}

@JsonSerializable()
class RankingResponse {
  final List<RankingEntryModel> ranking;
  final int totalParticipants;
  final RankingFilters? filters;

  const RankingResponse({
    required this.ranking,
    required this.totalParticipants,
    this.filters,
  });

  factory RankingResponse.fromJson(Map<String, dynamic> json) =>
      _$RankingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RankingResponseToJson(this);
}

@JsonSerializable()
class RankingFilters {
  final List<String>? raffleIds;
  final List<String>? eventIds;
  final List<String>? trackIds;
  final int? minParticipations;

  const RankingFilters({
    this.raffleIds,
    this.eventIds,
    this.trackIds,
    this.minParticipations,
  });

  factory RankingFilters.fromJson(Map<String, dynamic> json) =>
      _$RankingFiltersFromJson(json);

  Map<String, dynamic> toJson() => _$RankingFiltersToJson(this);
}

@JsonSerializable()
class RaffleRankingRequest {
  final List<String> raffleIds;

  const RaffleRankingRequest({required this.raffleIds});

  factory RaffleRankingRequest.fromJson(Map<String, dynamic> json) =>
      _$RaffleRankingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RaffleRankingRequestToJson(this);
}

@JsonSerializable()
class EventRankingRequest {
  final List<String> eventIds;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final String? allowedDomain;

  const EventRankingRequest({
    required this.eventIds,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowedDomain,
  });

  factory EventRankingRequest.fromJson(Map<String, dynamic> json) =>
      _$EventRankingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EventRankingRequestToJson(this);
}

@JsonSerializable()
class TrackRankingRequest {
  final List<String> trackIds;
  final int? minDurationMinutes;
  final int? minTalksCount;
  final String? allowedDomain;

  const TrackRankingRequest({
    required this.trackIds,
    this.minDurationMinutes,
    this.minTalksCount,
    this.allowedDomain,
  });

  factory TrackRankingRequest.fromJson(Map<String, dynamic> json) =>
      _$TrackRankingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TrackRankingRequestToJson(this);
}

@JsonSerializable()
class CreateVipRaffleRequest {
  final String name;
  final String? description;
  final String prize;
  final List<String>? raffleIds;
  final List<String>? eventIds;
  final List<String>? trackIds;
  final int minParticipations;
  final String? allowedDomain;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const CreateVipRaffleRequest({
    required this.name,
    this.description,
    required this.prize,
    this.raffleIds,
    this.eventIds,
    this.trackIds,
    required this.minParticipations,
    this.allowedDomain,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    this.startsAt,
    this.endsAt,
  });

  factory CreateVipRaffleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateVipRaffleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateVipRaffleRequestToJson(this);
}

@JsonSerializable()
class VipEligibleCountResponse {
  final int count;
  final int minParticipations;
  final String? source;

  const VipEligibleCountResponse({
    required this.count,
    required this.minParticipations,
    this.source,
  });

  factory VipEligibleCountResponse.fromJson(Map<String, dynamic> json) =>
      _$VipEligibleCountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VipEligibleCountResponseToJson(this);
}
