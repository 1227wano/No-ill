import 'package:dio/dio.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final Dio _dio;

  ScheduleService(this._dio);

  //// 1. 전체 일정 목록 조회 (수정 완료 ✅)
  Future<List<ScheduleModel>> fetchAllSchedules(String petId) async {
    try {
      // 💡 주소를 /api/schedules/pets 로 변경하고
      // 💡 petId를 queryParameters로 전달합니다.
      final response = await _dio.get(
        '/schedules/app',
        queryParameters: {'petId': petId},
      );

      print("🚀 호출 주소 확인: ${response.realUri}"); // 실제 호출된 전체 주소가 출력됩니다.

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("🚨 전체 일정 조회 실패: $e");
      return [];
    }
  }

  /// 2. 월별 일정 조회 (수정 완료 ✅)
  /// GET /api/schedules/app/month?petId=N0111&yearMonth=2026-02
  Future<List<ScheduleModel>> fetchMonthlySchedules(
    String petId,
    int year,
    int month,
  ) async {
    try {
      // 💡 1. 주소에서 $petId를 제거하고 '/api/schedules/app/month'로 고정합니다.
      // 💡 2. 'year'와 'month'를 서버가 원하는 'YYYY-MM' 형식으로 변환합니다.
      final String formattedMonth = month.toString().padLeft(2, '0');
      final String yearMonth = "$year-$formattedMonth";

      final response = await _dio.get(
        '/api/schedules/app/month',
        queryParameters: {
          'petId': petId, // 예: N0111
          'yearMonth': yearMonth, // 예: 2026-02
        },
      );

      print("🚀 월별 조회 호출: ${response.realUri}");

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("🚨 월별 일정 조회 실패: $e");
      return [];
    }
  }

  //// 3. 일별 일정 조회 (수정 완료 ✅)
  /// GET /api/schedules/app/day?petId=N0111&date=2026-02-03
  Future<List<ScheduleModel>> fetchDailySchedules(
    String petId,
    DateTime date,
  ) async {
    try {
      // 💡 서버가 원하는 YYYY-MM-DD 형식으로 날짜를 변환합니다.
      final String formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final response = await _dio.get(
        '/api/schedules/app/day',
        queryParameters: {
          'petId': petId, // 예: N0111
          'date': formattedDate, // 예: 2026-02-03
        },
      );

      print("🚀 일별 조회 호출: ${response.realUri}");

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("🚨 일별 일정 조회 실패: $e");
      return [];
    }
  }

  /// 4. 일정 등록 (POST /api/schedule)
  Future<bool> createSchedule(ScheduleModel schedule, String petId) async {
    try {
      // ✅ 사용자님이 제공해주신 Request 규격 반영
      final response = await _dio.post(
        '/schedules/app',
        data: schedule.toJson(petId),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("🚨 일정 등록 실패: $e");
      return false;
    }
  }

  // 5. 일정 수정 (디버깅 버전)
  Future<bool> updateSchedule(ScheduleModel schedule, String petId) async {
    if (schedule.id == null) {
      print("🚨 에러: schedule.id가 null입니다!");
      return false;
    }

    try {
      final body = schedule.toJson(petId); // 서버로 보낼 데이터
      final url = '/schedules/app/${schedule.id}'; // 호출할 주소

      print("📡 [수정 요청] 주소: $url");
      print("📡 [수정 요청] 데이터: $body"); // 💡 이 데이터를 유심히 보세요!

      final response = await _dio.put(url, data: body);

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        // 서버가 왜 400을 줬는지 상세 이유를 알려주는 경우가 많습니다.
        print("🚨 서버 응답 에러 상세: ${e.response?.data}");
      }
      print("🚨 일정 수정 실패: $e");
      return false;
    }
  }

  // schedule_service.dart

  Future<bool> deleteSchedule(int id, String petId) async {
    try {
      print("🗑️ 삭제 시도 - ID: $id, PetId: $petId");

      final response = await _dio.delete(
        '/schedules/app/$id',
        // 💡 핵심: DELETE 요청의 body에 petId를 담습니다.
        data: {'petId': petId},
        // 아까 논의한 대로 혹시 모를 500 에러 방지를 위해 추가
        options: Options(contentType: Headers.jsonContentType),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print("❌ [Service] 삭제 실패: ${e.response?.data}");
      return false;
    }
  }
}
