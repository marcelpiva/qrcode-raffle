import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet',
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erro ao acessar dados locais',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Não autorizado',
    super.statusCode = 401,
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Recurso não encontrado',
    super.statusCode = 404,
  });
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.statusCode = 409,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ocorreu um erro inesperado',
  });
}
