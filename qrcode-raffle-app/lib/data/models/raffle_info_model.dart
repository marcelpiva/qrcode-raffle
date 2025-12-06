import 'package:json_annotation/json_annotation.dart';

part 'raffle_info_model.g.dart';

/// Simplified raffle info for registration page
@JsonSerializable()
class RaffleInfoModel {
  final String id;
  final String name;
  final String? description;
  final String prize;
  final String status;
  final String? allowedDomain;
  final int participantCount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool requireConfirmation;
  final String? eventId;
  final String? talkId;
  final bool allowLinkRegistration;

  const RaffleInfoModel({
    required this.id,
    required this.name,
    this.description,
    required this.prize,
    required this.status,
    this.allowedDomain,
    required this.participantCount,
    this.startsAt,
    this.endsAt,
    this.requireConfirmation = false,
    this.eventId,
    this.talkId,
    this.allowLinkRegistration = true,
  });

  factory RaffleInfoModel.fromJson(Map<String, dynamic> json) =>
      _$RaffleInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$RaffleInfoModelToJson(this);

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isClosed => status.toUpperCase() == 'CLOSED';
  bool get isDrawn => status.toUpperCase() == 'DRAWN';
  bool get isEventRaffle => eventId != null && talkId == null;

  bool get hasNotStarted {
    if (startsAt == null) return false;
    return DateTime.now().isBefore(startsAt!);
  }

  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  bool get isOpen {
    if (!isActive) return false;
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
}
