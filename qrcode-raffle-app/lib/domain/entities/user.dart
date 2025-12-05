import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  participant;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.participant:
        return 'Participante';
    }
  }
}

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isParticipant => role == UserRole.participant;

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        fcmToken,
        createdAt,
        updatedAt,
      ];
}
