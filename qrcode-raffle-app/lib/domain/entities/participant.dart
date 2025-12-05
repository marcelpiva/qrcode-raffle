import 'package:equatable/equatable.dart';

class Participant extends Equatable {
  final String id;
  final String name;
  final String email;
  final String raffleId;
  final bool hasPin;
  final DateTime createdAt;
  final String? userId;

  const Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.raffleId,
    this.hasPin = false,
    required this.createdAt,
    this.userId,
  });

  Participant copyWith({
    String? id,
    String? name,
    String? email,
    String? raffleId,
    bool? hasPin,
    DateTime? createdAt,
    String? userId,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      raffleId: raffleId ?? this.raffleId,
      hasPin: hasPin ?? this.hasPin,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        raffleId,
        hasPin,
        createdAt,
        userId,
      ];
}
