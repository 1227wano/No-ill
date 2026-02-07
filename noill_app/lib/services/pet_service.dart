// lib/services/pet_service.dart

import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../core/utils/result.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/app_exception.dart';
import '../models/pet_model.dart';
import '../models/event_model.dart';

class PetService {
  final Dio _dio;
  final _logger = AppLogger('PetService');

  PetService(this._dio);

  // ═══════════════════════════════════════════════════════════════════════
  // 1. 어르신/로봇 정보 등록
  // ═══════════════════════════════════════════════════════════════════════

  /// 어르신 정보 등록
  ///
  /// Returns: [Success<PetModel>] 등록 성공
  ///          [Failure<PetModel>] 등록 실패
  Future<Result<PetModel>> registerCare({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      _logger.info('어르신 등록 시도: $petName ($petId)');

      // 요청 데이터 생성
      final pet = PetModel(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      final response = await _dio.post(
        ApiConstants.registerPet,
        data: pet.toJson(),
      );

      _logger.info('어르신 등록 성공: $petName');

      // 서버 응답 구조에 따라 분기
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : response.data;

      return Success(PetModel.fromJson(data));

    } on DioException catch (e, stackTrace) {
      _logger.error('어르신 등록 실패', e, stackTrace);
      return Failure(_handleDioException(e, '어르신 등록'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('어르신 등록 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. 내 어르신 목록 조회
  // ═══════════════════════════════════════════════════════════════════════

  /// 등록된 어르신 목록 조회
  ///
  /// Returns: [Success<List<PetModel>>] 조회 성공
  ///          [Failure<List<PetModel>>] 조회 실패
  Future<Result<List<PetModel>>> fetchMyPets() async {
    try {
      _logger.info('어르신 목록 조회 시작');

      final response = await _dio.get(ApiConstants.getMyPets);

      _logger.info('어르신 목록 조회 성공 (${response.statusCode})');

      // 응답 데이터 검증
      if (response.data == null) {
        _logger.warning('응답 데이터가 null입니다');
        return const Success([]);
      }

      // 데이터 파싱
      final List<dynamic> data = response.data;
      final pets = data.map((e) => PetModel.fromJson(e)).toList();

      _logger.info('총 ${pets.length}명의 어르신 정보 로드 완료');
      return Success(pets);

    } on DioException catch (e, stackTrace) {
      _logger.error('어르신 목록 조회 실패', e, stackTrace);
      return Failure(_handleDioException(e, '어르신 목록 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(ParseException(
        '서버 응답 데이터 형식이 올바르지 않습니다',
        originalError: e,
      ));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('목록 조회 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3. 기기 연결/로그인
  // ═══════════════════════════════════════════════════════════════════════

  /// 기기 ID로 어르신 정보 연결
  ///
  /// [petId]: 기기 고유 ID
  ///
  /// Returns: [Success<PetModel>] 연결 성공
  ///          [Failure<PetModel>] 연결 실패
  Future<Result<PetModel>> connectPet(String petId) async {
    try {
      _logger.info('기기 연결 시도: $petId');

      final response = await _dio.post(
        '/api/auth/pets/login',
        data: {'petId': petId},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.info('기기 연결 성공');
        return Success(PetModel.fromJson(response.data));
      }

      _logger.warning('기기 연결 실패: 응답 데이터 없음');
      return Failure(AppException('기기 연결에 실패했습니다'));

    } on DioException catch (e, stackTrace) {
      _logger.error('기기 연결 실패', e, stackTrace);

      // 403: 이미 등록된 기기
      if (e.response?.statusCode == 403) {
        return Failure(AppException(
          '이미 등록된 기기입니다',
          code: 'ALREADY_REGISTERED',
          originalError: e,
        ));
      }

      return Failure(_handleDioException(e, '기기 연결'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('기기 연결 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 4. 사고 기록 조회
  // ═══════════════════════════════════════════════════════════════════════

  /// 특정 어르신의 사고 기록 조회
  ///
  /// [petId]: 어르신 기기 ID
  ///
  /// Returns: [Success<List<EventModel>>] 조회 성공
  ///          [Failure<List<EventModel>>] 조회 실패
  Future<Result<List<EventModel>>> fetchEvents(String petId) async {
    try {
      _logger.info('사고 기록 조회 시작: $petId');

      final response = await _dio.get('/api/events/$petId');

      final List<dynamic> data = response.data;
      final events = data.map((json) => EventModel.fromJson(json, petId)).toList();

      _logger.info('사고 기록 ${events.length}건 조회 완료');
      return Success(events);

    } on DioException catch (e, stackTrace) {
      _logger.error('사고 기록 조회 실패', e, stackTrace);
      return Failure(_handleDioException(e, '사고 기록 조회'));
    } on TypeError catch (e, stackTrace) {
      _logger.error('데이터 파싱 실패', e, stackTrace);
      return Failure(ParseException(
        '사고 기록 데이터 형식이 올바르지 않습니다',
        originalError: e,
      ));
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
        if (statusCode == 404) {
          return ServerException(
            '요청한 정보를 찾을 수 없습니다',
            statusCode: 404,
            code: 'NOT_FOUND',
            originalError: e,
          );
        } else if (statusCode == 409) {
          return AppException(
            '이미 존재하는 데이터입니다',
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

    // 요청 취소
      case DioExceptionType.cancel:
        return AppException(
          '요청이 취소되었습니다',
          code: 'CANCELLED',
          originalError: e,
        );

    // SSL 인증서 에러
      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL 인증서 오류가 발생했습니다',
          code: 'BAD_CERTIFICATE',
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
