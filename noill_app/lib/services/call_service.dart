// lib/features/call/services/openvidu_service.dart
import 'package:dio/dio.dart';

class OpenViduService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://i14a301.p.ssafy.io/api"));

  // [Step 2-1] 세션 생성 (보호자용)
  Future<String?> createSession() async {
    final response = await _dio.post("/openvidu/sessions", data: {});
    return response.data; // "ses_JM9v0..."
  }

  // [Step 2-2 & 4] 입장권(Token) 받기 (보호자 & 로봇 공통)
  Future<String?> getConnectionToken(String sessionId) async {
    final response = await _dio.post(
      "/openvidu/sessions/$sessionId/connections",
    );
    return response.data; // "wss://..."
  }

  // [Step 2-3] 디스플레이 깨우기 (FCM 발송 요청)
  Future<bool> notifyCall(String petId, String sessionId) async {
    final response = await _dio.post(
      "/openvidu/call",
      data: {"petId": petId, "sessionId": sessionId},
    );
    return response.statusCode == 200;
  }
}
