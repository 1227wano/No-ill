// lib/services/event_service.dart

import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../core/utils/result.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/app_exception.dart';

class EventService {
  final Dio _dio;
  final _logger = AppLogger('EventService');

  EventService(this._dio);

  // ═══════════════════════════════════════════════════════════════════════
  // 사고 기록 조회
  // ═══════════════════════════════════════════════════════════════════════

  /// 특정 어르신의 모든 사고 기록 조회
  ///
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<List<EventModel>>] 조회 성공 (빈 리스트 포함)
  ///          [Failure<List<EventModel>>] 조회 실패
  Future<Result<List<EventModel>>> fetchEvents(String petId) async {
    try {
      _logger.info('사고 기록 조회 시작: $petId');

      final response = await _dio.get('/api/events/$petId');

      _logger.info('응답 수신: ${response.statusCode}');
      _logger.debug('응답 데이터: ${response.data}');

      // 응답 검증
      if (response.statusCode == 200) {
        // 데이터가 null이면 빈 리스트 반환
        if (response.data == null) {
          _logger.info('응답 데이터가 null - 빈 리스트 반환');
          return const Success([]);
        }

        // 데이터 파싱
        final List<dynamic> data = response.data;
        final events = data
            .map((json) => EventModel.fromJson(json, petId))
            .toList();

        _logger.info('사고 기록 ${events.length}건 조회 완료');
        return Success(events);
      }

      // 200이 아닌 경우
      _logger.warning('예상치 못한 응답 코드: ${response.statusCode}');
      return const Success([]); // 빈 리스트 반환
    } on DioException catch (e, stackTrace) {
      _logger.error('사고 기록 조회 실패', e, stackTrace);

      // 404 또는 500: 데이터 없음으로 간주
      if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
        _logger.info('${e.response?.statusCode} 에러 - 빈 리스트 반환');
        return const Success([]); // 에러지만 빈 리스트 성공으로 처리
      }

      // 그 외 네트워크 에러
      return Failure(_handleDioException(e, '사고 기록 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(
        ParseException('사고 기록 데이터 형식이 올바르지 않습니다', originalError: e),
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('사고 기록 조회 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private: 에러 처리
  // ═══════════════════════════════════════════════════════════════════════

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
        if (statusCode == 401 || statusCode == 403) {
          return AuthException('인증이 만료되었습니다', originalError: e);
        } else if (statusCode == 404) {
          return ServerException(
            '요청한 정보를 찾을 수 없습니다',
            statusCode: 404,
            code: 'NOT_FOUND',
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            '서버 오류가 발생했습니다',
            statusCode: statusCode,
            code: 'SERVER_ERROR',
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
        return AppException('요청이 취소되었습니다', code: 'CANCELLED', originalError: e);

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
