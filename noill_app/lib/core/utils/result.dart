// lib/core/utils/result.dart

import '../exceptions/app_exception.dart';

/// Success 또는 Failure를 나타내는 Result 타입
sealed class Result<T> {
  const Result();
}

/// 성공
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// 실패
class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Result 확장 메서드
extension ResultExtension<T> on Result<T> {
  /// 성공인지 확인
  bool get isSuccess => this is Success<T>;

  /// 실패인지 확인
  bool get isFailure => this is Failure<T>;

  /// 데이터 가져오기 (성공 시)
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// 에러 가져오기 (실패 시)
  AppException? get errorOrNull =>
      this is Failure<T> ? (this as Failure<T>).exception : null;

  /// fold 패턴
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Failure(exception: final error) => onFailure(error),
    };
  }

  /// map 패턴
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Failure(exception: final error) => Failure(error),
    };
  }
}
