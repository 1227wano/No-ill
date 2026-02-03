import 'package:dio/dio.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final Dio _dio;

  ScheduleService(this._dio);

  /// 1. 전체 일정 목록 조회 (GET /api/schedule/{petId})
  Future<List<ScheduleModel>> fetchAllSchedules(String petId) async {
    try {
      final response = await _dio.get('/schedules/$petId');

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

  /// 2. 월별 일정 조회 (GET /api/schedule/month/{petId}?year=2026&month=2)
  Future<List<ScheduleModel>> fetchMonthlySchedules(
    String petId,
    int year,
    int month,
  ) async {
    try {
      final response = await _dio.get(
        '/schedules/month/$petId',
        queryParameters: {'year': year, 'month': month},
      );

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

  /// 3. 일별 일정 조회 (GET /api/schedule/day/{petId}?date=2026-02-03)
  Future<List<ScheduleModel>> fetchDailySchedules(
    String petId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '/schedules/day/$petId',
        queryParameters: {'date': date},
      );

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
        '/schedules',
        data: schedule.toJson(petId),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("🚨 일정 등록 실패: $e");
      return false;
    }
  }

  /// 5. 일정 수정 (PUT /api/schedule/{id})
  Future<bool> updateSchedule(ScheduleModel schedule, String petId) async {
    if (schedule.id == null) return false;

    try {
      final response = await _dio.put(
        '/schedules/${schedule.id}',
        data: schedule.toJson(petId),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("🚨 일정 수정 실패: $e");
      return false;
    }
  }

  /// 6. 일정 삭제 (DELETE /api/schedule/{id})
  Future<bool> deleteSchedule(int id) async {
    try {
      final response = await _dio.delete('/schedules/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("🚨 일정 삭제 실패: $e");
      return false;
    }
  }
}
