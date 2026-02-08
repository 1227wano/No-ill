// lib/core/exceptions/app_exception.dart

/// 앱 전체에서 사용하는 기본 Exception
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// 네트워크 에러
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

/// 인증 에러
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// 서버 에러
class ServerException extends AppException {
  final int? statusCode;

  ServerException(
      super.message, {
        this.statusCode,
        super.code,
        super.originalError,
      });

  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' ($statusCode)' : ''}';
}

/// 데이터 파싱 에러
class ParseException extends AppException {
  ParseException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'ParseException: $message';
}
