// lib/features/call/services/openvidu_service.dart
import 'package:dio/dio.dart';

class OpenViduService {
  final Dio _dio;
  OpenViduService(this._dio);

  // [Step 1] 세션 생성 (보호자가 통화를 시작할 때 방 생성)
  Future<String?> createSession() async {
    try {
      final response = await _dio.post('/openvidu/sessions', data: {});

      if (response.statusCode == 200) {
        return response.data.toString();
      }
    } on DioException catch (e) {
      print("❌ 세션 생성 실패: ${e.response?.statusCode}");
      rethrow;
    }
    return null;
  }

  // [Step 2] 디스플레이 깨우기 (상대방 petId에게 세션 정보 전달)
  Future<bool> notifyCall(String petId, String sessionId) async {
    try {
      final response = await _dio.post(
        "/openvidu/call/pet",
        data: {"petId": petId, "sessionId": sessionId},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ [OpenVidu] 상대방 호출 실패: $e");
      return false;
    }
  }

  // [Step 3] 입장권(Token) 받기 (실제 화상 스트림 연결용 주소)
  Future<String?> getConnectionToken(String sessionId) async {
    try {
      final response = await _dio.post(
        "/openvidu/sessions/$sessionId/connections",
      );
      return response.data.toString();
    } catch (e) {
      print("❌ [OpenVidu] 토큰 발급 실패: $e");
      return null;
    }
  }
}
