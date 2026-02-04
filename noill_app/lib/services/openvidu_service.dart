// lib/features/call/services/openvidu_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';

// 서비스 프로바이더 등록
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://i14a301.p.ssafy.io/api', // 🎯 http -> https 확인
    followRedirects: true, // 🎯 리다이렉트 허용
    validateStatus: (status) => status! < 500, // 🎯 301도 에러로 던지지 않음
  ),
);

class OpenViduService {
  final Dio _dio;
  OpenViduService(this._dio);

  // [Step 1] 세션 생성 (보호자가 통화를 시작할 때 방 생성)
  // lib/services/open_vidu_service.dart

  Future<String?> createSession() async {
    try {
      // 🎯 1. 저장된 토큰 가져오기 (이미 가지고 계신 토큰 변수 사용)
      String? token = "아까 로그에 찍혔던 그 토큰값";

      final response = await dio.post(
        '/openvidu/sessions', // 엔드포인트 확인
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // 🎯 2. Bearer 꼭 확인!
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['sessionId'];
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
        "/openvidu/call",
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
      // 서버 응답 구조에 따라 수정 (예: response.data['token'])
      return response.data.toString();
    } catch (e) {
      print("❌ [OpenVidu] 토큰 발급 실패: $e");
      return null;
    }
  }
}
