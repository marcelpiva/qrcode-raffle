class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Sem conexão com a internet',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Erro ao acessar dados locais',
  });

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;

  const AuthException({
    this.message = 'Não autorizado',
  });

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({
    this.message = 'Recurso não encontrado',
  });

  @override
  String toString() => 'NotFoundException: $message';
}

class ConflictException implements Exception {
  final String message;

  const ConflictException({
    required this.message,
  });

  @override
  String toString() => 'ConflictException: $message';
}
