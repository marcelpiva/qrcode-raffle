import 'package:equatable/equatable.dart';

class RankingEntry extends Equatable {
  final String email;
  final String normalizedEmail;
  final int participationCount;
  final int wins;
  final List<String> names;
  final int position;

  const RankingEntry({
    required this.email,
    required this.normalizedEmail,
    required this.participationCount,
    required this.wins,
    required this.names,
    required this.position,
  });

  String get displayName => names.isNotEmpty ? names.first : email;

  double get winRate =>
      participationCount > 0 ? (wins / participationCount) * 100 : 0;

  RankingEntry copyWith({
    String? email,
    String? normalizedEmail,
    int? participationCount,
    int? wins,
    List<String>? names,
    int? position,
  }) {
    return RankingEntry(
      email: email ?? this.email,
      normalizedEmail: normalizedEmail ?? this.normalizedEmail,
      participationCount: participationCount ?? this.participationCount,
      wins: wins ?? this.wins,
      names: names ?? this.names,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [
        email,
        normalizedEmail,
        participationCount,
        wins,
        names,
        position,
      ];
}
