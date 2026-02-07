// lib/services/schedule_service.dart

import 'package:dio/dio.dart';
import '../models/schedule_model.dart';
import '../core/utils/result.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/app_exception.dart';

class ScheduleService {
  final Dio _dio;
  final _logger = AppLogger('ScheduleService');

  ScheduleService(this._dio);

  // ═══════════════════════════════════════════════════════════════════════
  // 1. 일정 조회
  // ═══════════════════════════════════════════════════════════════════════

  /// 전체 일정 목록 조회
  ///
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<List<ScheduleModel>>] 조회 성공
  ///          [Failure<List<ScheduleModel>>] 조회 실패
  Future<Result<List<ScheduleModel>>> fetchAllSchedules(String petId) async {
    try {
      _logger.info('전체 일정 조회: $petId');

      final response = await _dio.get(
        '/api/schedules/app',
        queryParameters: {'petId': petId},
      );

      _logger.debug('요청 URL: ${response.realUri}');
      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          _logger.info('응답 데이터가 null - 빈 리스트 반환');
          return const Success([]);
        }

        final List<dynamic> data = response.data;
        final schedules = data.map((json) => ScheduleModel.fromJson(json)).toList();

        _logger.info('일정 ${schedules.length}개 조회 완료');
        return Success(schedules);
      }

      _logger.warning('예상치 못한 응답 코드: ${response.statusCode}');
      return const Success([]);

    } on DioException catch (e, stackTrace) {
      _logger.error('전체 일정 조회 실패', e, stackTrace);
      return Failure(_handleDioException(e, '전체 일정 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(ParseException('일정 데이터 형식이 올바르지 않습니다', originalError: e));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 조회 중 오류가 발생했습니다'));
    }
  }

  /// 월별 일정 조회
  ///
  /// [petId]: 어르신 기기 ID
  /// [year]: 년도
  /// [month]: 월 (1-12)
  ///
  /// Returns: [Success<List<ScheduleModel>>] 조회 성공
  ///          [Failure<List<ScheduleModel>>] 조회 실패
  Future<Result<List<ScheduleModel>>> fetchMonthlySchedules(
      String petId,
      int year,
      int month,
      ) async {
    try {
      // YYYY-MM 형식으로 변환
      final yearMonth = _formatYearMonth(year, month);
      _logger.info('월별 일정 조회: $petId / $yearMonth');

      final response = await _dio.get(
        '/api/schedules/app/month',
        queryParameters: {
          'petId': petId,
          'yearMonth': yearMonth,
        },
      );

      _logger.debug('요청 URL: ${response.realUri}');
      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          _logger.info('응답 데이터가 null - 빈 리스트 반환');
          return const Success([]);
        }

        final List<dynamic> data = response.data;
        final schedules = data.map((json) => ScheduleModel.fromJson(json)).toList();

        _logger.info('일정 ${schedules.length}개 조회 완료');
        return Success(schedules);
      }

      _logger.warning('예상치 못한 응답 코드: ${response.statusCode}');
      return const Success([]);

    } on DioException catch (e, stackTrace) {
      _logger.error('월별 일정 조회 실패', e, stackTrace);
      return Failure(_handleDioException(e, '월별 일정 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(ParseException('일정 데이터 형식이 올바르지 않습니다', originalError: e));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 조회 중 오류가 발생했습니다'));
    }
  }

  /// 일별 일정 조회
  ///
  /// [petId]: 어르신 기기 ID
  /// [date]: 조회할 날짜
  ///
  /// Returns: [Success<List<ScheduleModel>>] 조회 성공
  ///          [Failure<List<ScheduleModel>>] 조회 실패
  Future<Result<List<ScheduleModel>>> fetchDailySchedules(
      String petId,
      DateTime date,
      ) async {
    try {
      // YYYY-MM-DD 형식으로 변환
      final formattedDate = _formatDate(date);
      _logger.info('일별 일정 조회: $petId / $formattedDate');

      final response = await _dio.get(
        '/api/schedules/app/day',
        queryParameters: {
          'petId': petId,
          'date': formattedDate,
        },
      );

      _logger.debug('요청 URL: ${response.realUri}');
      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          _logger.info('응답 데이터가 null - 빈 리스트 반환');
          return const Success([]);
        }

        final List<dynamic> data = response.data;
        final schedules = data.map((json) => ScheduleModel.fromJson(json)).toList();

        _logger.info('일정 ${schedules.length}개 조회 완료');
        return Success(schedules);
      }

      _logger.warning('예상치 못한 응답 코드: ${response.statusCode}');
      return const Success([]);

    } on DioException catch (e, stackTrace) {
      _logger.error('일별 일정 조회 실패', e, stackTrace);
      return Failure(_handleDioException(e, '일별 일정 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(ParseException('일정 데이터 형식이 올바르지 않습니다', originalError: e));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 조회 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. 일정 생성
  // ═══════════════════════════════════════════════════════════════════════

  /// 일정 생성
  ///
  /// [schedule]: 생성할 일정 정보
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<ScheduleModel>] 생성 성공
  ///          [Failure<ScheduleModel>] 생성 실패
  Future<Result<ScheduleModel>> createSchedule(
      ScheduleModel schedule,
      String petId,
      ) async {
    try {
      _logger.info('일정 생성: ${schedule.schName}');

      final requestData = schedule.toJson(petId);
      _logger.debug('요청 데이터: $requestData');

      final response = await _dio.post(
        '/api/schedules/app',
        data: requestData,
      );

      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('일정 생성 성공');

        // 생성된 일정 반환 (서버가 ID를 부여한 데이터)
        if (response.data != null) {
          return Success(ScheduleModel.fromJson(response.data));
        }

        // 응답에 데이터가 없으면 원본 반환
        return Success(schedule);
      }

      _logger.warning('일정 생성 실패: ${response.statusCode}');
      return Failure(AppException('일정 생성에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('일정 생성 실패', e, stackTrace);
      return Failure(_handleDioException(e, '일정 생성'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 생성 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3. 일정 수정
  // ═══════════════════════════════════════════════════════════════════════

  /// 일정 수정
  ///
  /// [schedule]: 수정할 일정 정보 (ID 필수)
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<ScheduleModel>] 수정 성공
  ///          [Failure<ScheduleModel>] 수정 실패
  Future<Result<ScheduleModel>> updateSchedule(
      ScheduleModel schedule,
      String petId,
      ) async {
    // ID 검증
    if (schedule.id == null) {
      _logger.error('일정 수정 실패: ID가 null입니다');
      return Failure(AppException('일정 ID가 없습니다'));
    }

    try {
      _logger.info('일정 수정: ID=${schedule.id}, ${schedule.schName}');

      final requestData = schedule.toJson(petId);
      final url = '/api/schedules/app/${schedule.id}';

      _logger.debug('요청 URL: $url');
      _logger.debug('요청 데이터: $requestData');

      final response = await _dio.put(url, data: requestData);

      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200) {
        _logger.info('일정 수정 성공');

        // 수정된 일정 반환
        if (response.data != null) {
          return Success(ScheduleModel.fromJson(response.data));
        }

        // 응답에 데이터가 없으면 원본 반환
        return Success(schedule);
      }

      _logger.warning('일정 수정 실패: ${response.statusCode}');
      return Failure(AppException('일정 수정에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('일정 수정 실패', e, stackTrace);

      // 400 에러 시 상세 정보 로깅
      if (e.response?.statusCode == 400) {
        _logger.error('서버 응답 상세: ${e.response?.data}');
      }

      return Failure(_handleDioException(e, '일정 수정'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 수정 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 4. 일정 삭제
  // ═══════════════════════════════════════════════════════════════════════

  /// 일정 삭제
  ///
  /// [id]: 삭제할 일정 ID
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<void>] 삭제 성공
  ///          [Failure<void>] 삭제 실패
  Future<Result<void>> deleteSchedule(int id, String petId) async {
    try {
      _logger.info('일정 삭제: ID=$id, PetId=$petId');

      final response = await _dio.delete(
        '/api/schedules/app/$id',
        data: {'petId': petId},
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      _logger.info('응답 수신: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.info('일정 삭제 성공');
        return const Success(null);
      }

      _logger.warning('일정 삭제 실패: ${response.statusCode}');
      return Failure(AppException('일정 삭제에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('일정 삭제 실패', e, stackTrace);
      _logger.error('서버 응답: ${e.response?.data}');
      return Failure(_handleDioException(e, '일정 삭제'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('일정 삭제 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private: 유틸리티
  // ═══════════════════════════════════════════════════════════════════════

  /// 년월을 YYYY-MM 형식으로 변환
  String _formatYearMonth(int year, int month) {
    final formattedMonth = month.toString().padLeft(2, '0');
    return '$year-$formattedMonth';
  }

  /// 날짜를 YYYY-MM-DD 형식으로 변환
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// DioException을 AppException으로 변환
  AppException _handleDioException(DioException e, String operation) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '네트워크 연결 시간이 초과되었습니다',
          code: 'TIMEOUT',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '네트워크 연결을 확인해주세요',
          code: 'CONNECTION_ERROR',
          originalError: e,
        );

      case DioExceptionType.badResponse:
        if (statusCode == 400) {
          final serverMessage = e.response?.data?['message'] as String?;
          return AppException(
            serverMessage ?? '잘못된 요청입니다',
            code: 'BAD_REQUEST',
            originalError: e,
          );
        } else if (statusCode == 401 || statusCode == 403) {
          return AuthException('인증이 만료되었습니다', originalError: e);
        } else if (statusCode == 404) {
          return ServerException(
            '요청한 일정을 찾을 수 없습니다',
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

      case DioExceptionType.cancel:
        return AppException(
          '요청이 취소되었습니다',
          code: 'CANCELLED',
          originalError: e,
        );

      default:
        return AppException(
          '알 수 없는 오류가 발생했습니다',
          code: 'UNKNOWN',
          originalError: e,
        );
    }
  }
}
