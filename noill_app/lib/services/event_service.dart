import 'package:dio/dio.dart';
import '../models/event_models.dart'; //

class EventService {
  final Dio _dio;
  EventService(this._dio);

  /// [1-1. 실제 사고 기록 전체 조회 (나중에 사용)]
  /// 서버가 준비되면 아래 함수의 이름을 fetchAccidents로 바꾸고 사용하세요.
  Future<List<FallEvent>> fetchAccidentsReal() async {
    try {
      // ✅ 알려주신 사고 전용 엔드포인트 사용
      final response = await _dio.get('/api/events/report');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        // JSON 리스트를 FallEvent 객체 리스트로 변환하여 반환합니다.
        return data.map((json) => FallEvent.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('❌ [EventService] 조회 실패: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) {
      print('❌ [EventService] 알 수 없는 에러: $e');
      rethrow;
    }
  }

  /// [2. 낙상 사고 보고 (신규 추가)]
  /// 목적: 앱 내에서 낙상이 감지되었을 때 서버에 해당 이벤트를 기록으로 남깁니다.
  // Future<bool> reportFallEvent({
  //   required String description,
  //   required String filePath,
  // }) async {
  //   try {
  //     // 1. Multipart 전송을 위한 FormData 생성
  //     final formData = FormData.fromMap({
  //       'title': '낙상 감지 이벤트',
  //       'description': description,
  //       'file': await MultipartFile.fromFile(filePath), // 👈 파일을 바이너리로 변환
  //       'createdAt': DateTime.now().toIso8601String(),
  //     });

  //     // 2. POST 요청으로 서버에 데이터 전송
  //     final response = await _dio.post(
  //       '/api/events/report',
  //       data: formData,
  //     );

  //     return response.statusCode == 200 || response.statusCode == 201;
  //   } on DioException catch (e) {
  //     print('❌ [EventService] 사고 보고 실패 (500 에러 등): ${e.response?.statusCode}');
  //     return false;
  //   } catch (e) {
  //     print('❌ [EventService] 보고 중 예외 발생: $e');
  //     return false;
  //   }
  // }

  // [TEST] MOCKUP 데이터 반환
  Future<List<FallEvent>> fetchAccidents() async {
    // 실제 API 호출 대신 1초 쉬었다가 가짜 데이터를 돌려줌
    await Future.delayed(const Duration(seconds: 1));

    return [
      FallEvent(
        id: "evt_001",
        title: "⚠️ 거실 낙상 감지",
        description: "거실 소파 근처에서 어르신의 낙상이 감지되었습니다. 즉시 확인이 필요합니다.",
        imageUrl:
            "https://images.unsplash.com/photo-1516733968668-dbdce39c46ef?q=80&w=800",
        detectedAt: DateTime.now().subtract(
          const Duration(minutes: 45),
        ), // 45분 전 (최근 사고)
      ),
      FallEvent(
        id: "evt_002",
        title: "⚠️ 침실 낙상 감지",
        description: "침대 하단에서 미끄러짐이 감지되었습니다. 통화를 시도해 보세요.",
        imageUrl:
            "https://images.unsplash.com/photo-1581056771107-24ca5f033842?q=80&w=800",
        detectedAt: DateTime.now().subtract(
          const Duration(hours: 5),
        ), // 5시간 전 (최근 사고)
      ),
      FallEvent(
        id: "evt_003",
        title: "⚠️ 주방 사고 기록",
        description: "어제 오후 식탁 근처에서 발생한 사고 기록입니다.",
        imageUrl:
            "https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?q=80&w=800",
        detectedAt: DateTime.now().subtract(
          const Duration(hours: 32),
        ), // 32시간 전 (24시간 경과 - 만료 테스트용)
      ),
    ];
  }
}
