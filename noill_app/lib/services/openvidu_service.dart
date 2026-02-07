// lib/services/openvidu_service.dart

import 'package:dio/dio.dart';
import '../core/utils/result.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/app_exception.dart';

class OpenViduService {
  final Dio _dio;
  final _logger = AppLogger('OpenViduService');

  OpenViduService(this._dio);

  // ═══════════════════════════════════════════════════════════════════════
  // 1. 세션 생성
  // ═══════════════════════════════════════════════════════════════════════

  /// OpenVidu 세션 생성
  ///
  /// 보호자가 통화를 시작할 때 호출됩니다.
  ///
  /// Returns: [Success<String>] 세션 ID
  ///          [Failure<String>] 생성 실패
  Future<Result<String>> createSession() async {
    try {
      _logger.info('OpenVidu 세션 생성 요청');

      final response = await _dio.post(
        '/api/openvidu/sessions',
        data: {},
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      _logger.debug('응답 상태: ${response.statusCode}');
      _logger.debug('응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final sessionId = _cleanPlainTextResponse(response.data);
        _logger.info('세션 생성 성공: $sessionId');
        return Success(sessionId);
      }

      _logger.warning('세션 생성 실패: 응답 데이터 없음');
      return Failure(AppException('세션 생성에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('세션 생성 실패', e, stackTrace);
      return Failure(_handleDioException(e, '세션 생성'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('세션 생성 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. 상대방 호출 (디스플레이 깨우기)
  // ═══════════════════════════════════════════════════════════════════════

  /// 상대방(어르신)에게 통화 알림 전송
  ///
  /// [petId]: 어르신 기기 ID
  /// [sessionId]: 생성된 세션 ID
  ///
  /// Returns: [Success<void>] 알림 성공
  ///          [Failure<void>] 알림 실패
  Future<Result<void>> notifyCall(String petId, String sessionId) async {
    try {
      _logger.info('상대방 호출 요청: $petId (세션: $sessionId)');

      final response = await _dio.post(
        '/api/openvidu/call/pet',
        data: {
          'petId': petId,
          'sessionId': sessionId,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('상대방 호출 성공');
        return const Success(null);
      }

      _logger.warning('상대방 호출 실패: ${response.statusCode}');
      return Failure(AppException('상대방 호출에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('상대방 호출 실패', e, stackTrace);
      return Failure(_handleDioException(e, '상대방 호출'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('상대방 호출 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3. 연결 토큰 발급
  // ═══════════════════════════════════════════════════════════════════════

  /// OpenVidu 연결 토큰 발급
  ///
  /// 실제 WebRTC 연결을 위한 토큰을 받아옵니다.
  ///
  /// [sessionId]: 세션 ID
  ///
  /// Returns: [Success<String>] 연결 토큰
  ///          [Failure<String>] 발급 실패
  Future<Result<String>> getConnectionToken(String sessionId) async {
    try {
      _logger.info('연결 토큰 발급 요청: $sessionId');

      final response = await _dio.post(
        '/api/openvidu/sessions/$sessionId/connections',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      _logger.debug('응답 상태: ${response.statusCode}');
      _logger.debug('응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final token = _cleanPlainTextResponse(response.data);
        _logger.info('토큰 발급 성공: ${token.substring(0, 30)}...');
        return Success(token);
      }

      _logger.warning('토큰 발급 실패: 응답 데이터 없음');
      return Failure(AppException('토큰 발급에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('토큰 발급 실패', e, stackTrace);
      return Failure(_handleDioException(e, '토큰 발급'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('토큰 발급 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private: 유틸리티 메서드
  // ═══════════════════════════════════════════════════════════════════════

  /// Plain Text 응답 정제
  ///
  /// 서버가 반환하는 Plain Text 응답에서 불필요한 따옴표 등을 제거합니다.
  String _cleanPlainTextResponse(dynamic data) {
    return data.toString().trim().replaceAll('"', '');
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
        if (statusCode == 404) {
          return ServerException(
            '세션을 찾을 수 없습니다',
            statusCode: 404,
            code: 'SESSION_NOT_FOUND',
            originalError: e,
          );
        } else if (statusCode == 409) {
          return ServerException(
            '이미 진행 중인 통화가 있습니다',
            statusCode: 409,
            code: 'CALL_IN_PROGRESS',
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            'OpenVidu 서버 오류가 발생했습니다',
            statusCode: statusCode,
            code: 'OPENVIDU_SERVER_ERROR',
            originalError: e,
          );
        }

        final serverMessage = e.response?.data?['message'] as String?;
        return ServerException(
          serverMessage ?? '$operation 처리 중 오류가 발생했습니다',
          statusCode: statusCode,
          originalError: e,
        );

    // 요청 취소
      case DioExceptionType.cancel:
        return AppException(
          '요청이 취소되었습니다',
          code: 'CANCELLED',
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
}
