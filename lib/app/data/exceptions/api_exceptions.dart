/// Custom exception classes for API error handling
class ValidationException implements Exception {
  final String message;
  final String code;
  ValidationException(this.message, this.code);

  @override
  String toString() => 'ValidationException: $message (Code: $code)';
}

class NotFoundException implements Exception {
  final String message;
  final String code;
  NotFoundException(this.message, this.code);

  @override
  String toString() => 'NotFoundException: $message (Code: $code)';
}

class ConflictException implements Exception {
  final String message;
  final String code;
  ConflictException(this.message, this.code);

  @override
  String toString() => 'ConflictException: $message (Code: $code)';
}

class UnauthorizedException implements Exception {
  final String message;
  final String code;
  UnauthorizedException(this.message, this.code);

  @override
  String toString() => 'UnauthorizedException: $message (Code: $code)';
}

class ForbiddenException implements Exception {
  final String message;
  final String code;
  ForbiddenException(this.message, this.code);

  @override
  String toString() => 'ForbiddenException: $message (Code: $code)';
}

class ServerException implements Exception {
  final String message;
  final String code;
  ServerException(this.message, this.code);

  @override
  String toString() => 'ServerException: $message (Code: $code)';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
