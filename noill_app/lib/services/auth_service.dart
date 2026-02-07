// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import '../core/exceptions/app_exception.dart';
import '../models/auth_model.dart';
import 'fcm_service.dart';

// ⭐ Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio, ref);
});

class AuthService {
  final Dio _dio;
  final Ref _ref;
  final _logger = AppLogger('AuthService');

  AuthService(this._dio, this._ref);

  /// [로그인]
  Future<Result<LoginResponse>> login(String id, String password) async {
    try {
      _logger.info('로그인 시도: $id');

      final response = await _dio.post(
        ApiConstants.login,
        data: {
          "userId": id,
          "userPassword": password,
        },
      );

      _logger.info('로그인 성공');

      final loginResponse = LoginResponse.fromJson(response.data);

      // FCM 토큰 등록 (비동기, 에러가 나도 로그인은 성공)
      _registerFcmTokenAfterLogin();

      return Success(loginResponse);

    } on DioException catch (e, stackTrace) {
      _logger.error('로그인 실패', e, stackTrace);
      return Failure(_handleDioException(e, '로그인'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('로그인 중 오류가 발생했습니다'));
    }
  }

  /// [회원가입]
  Future<Result<CommonResponse>> signUp(SignupRequest request) async {
    try {
      _logger.info('회원가입 시도: ${request.userId}');

      final response = await _dio.post(
        ApiConstants.signup,
        data: request.toJson(),
      );

      _logger.info('회원가입 성공');

      return Success(CommonResponse.fromJson(response.data));

    } on DioException catch (e, stackTrace) {
      _logger.error('회원가입 실패', e, stackTrace);
      return Failure(_handleDioException(e, '회원가입'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('회원가입 중 오류가 발생했습니다'));
    }
  }

  /// [로그아웃]
  /// ⚠️ 주의: 서버에 로그아웃을 통보만 합니다.
  /// 실제 기기의 토큰 삭제는 AuthProvider에서 처리해야 합니다.
  Future<Result<CommonResponse>> logout() async {
    try {
      _logger.info('로그아웃 시도');

      final response = await _dio.post(ApiConstants.logout);

      _logger.info('로그아웃 성공');

      return Success(CommonResponse.fromJson(response.data));

    } on DioException catch (e, stackTrace) {
      _logger.error('로그아웃 실패', e, stackTrace);
      return Failure(_handleDioException(e, '로그아웃'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('로그아웃 중 오류가 발생했습니다'));
    }
  }

  /// DioException을 AppException으로 변환
  AppException _handleDioException(DioException e, String operation) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
    // 타임아웃 에러
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '네트워크 연결 시간이 초과되었습니다',
          code: 'TIMEOUT',
          originalError: e,
        );

    // 연결 에러
      case DioExceptionType.connectionError:
        return NetworkException(
          '네트워크 연결을 확인해주세요',
          code: 'CONNECTION_ERROR',
          originalError: e,
        );

    // 서버 응답 에러
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return AuthException(
            '아이디 또는 비밀번호가 올바르지 않습니다',
            code: 'INVALID_CREDENTIALS',
            originalError: e,
          );
        } else if (statusCode == 403) {
          return AuthException(
            '접근 권한이 없습니다',
            code: 'FORBIDDEN',
            originalError: e,
          );
        } else if (statusCode == 409) {
          return AppException(
            '이미 존재하는 계정입니다',
            code: 'DUPLICATE',
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요',
            statusCode: statusCode,
            code: 'SERVER_ERROR',
            originalError: e,
          );
        }

        // 서버 응답 메시지 사용
        final serverMessage = e.response?.data?['message'] as String?;
        return ServerException(
          serverMessage ?? '$operation 처리 중 오류가 발생했습니다',
          statusCode: statusCode,
          originalError: e,
        );

    // 기타 에러
      default:
        return AppException(
          '알 수 없는 오류가 발생했습니다',
          code: 'UNKNOWN',
          originalError: e,
        );
    }
  }

  /// FCM 토큰 등록 (로그인 후 자동 실행)
  Future<void> _registerFcmTokenAfterLogin() async {
    try {
      final fcmService = _ref.read(fcmServiceProvider);
      final token = await fcmService.getFcmToken();

      if (token != null) {
        await fcmService.sendTokenToServer(token);
        _logger.info('FCM 토큰 자동 등록 완료');
      } else {
        _logger.warning('FCM 토큰이 없습니다');
      }
    } catch (e, stackTrace) {
      // ⚠️ FCM 등록 실패는 로그인에 지장 없음
      _logger.warning('FCM 토큰 등록 실패 (로그인은 성공): $e');
    }
  }
}
