import 'package:dio/dio.dart';
import 'package:noill_app/models/event_model.dart';

class EventService {
  final Dio _dio;
  EventService(this._dio);

  /// ✅ [수정완료] 특정 어르신(petId)의 모든 사고 기록 조회
  /// 엔드포인트: /api/events/{petId}
  Future<List<EventModel>> fetchEvents(String petId) async {
    try {
      final response = await _dio.get('/events/report');
      print(response.data);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => EventModel.fromJson(json, petId)).toList();
      }
      return []; // 200이 아니면 일단 빈 리스트
    } on DioException catch (e) {
      // 💡 핵심: 500 에러나 404 에러가 나면 "데이터 없음"으로 간주하고 빈 리스트 반환
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        print(
          "⚠️ [EventService] ${e.response?.statusCode} 발생: 데이터를 빈 값으로 처리합니다.",
        );
        return [];
      }
      print("❌ [EventService] 진짜 통신 에러: ${e.message}");
      return []; // 에러 시 앱이 멈추지 않도록 빈 리스트 반환
    }
  }
}
