import 'package:dio/dio.dart';

class OpenViduService {
  final Dio _dio;
  OpenViduService(this._dio);

  // [Step 1] 세션 생성 (보호자가 통화를 시작할 때 방 생성)
    Future<String?> createSession() async {
      try {
        final response = await _dio.post(
          '/openvidu/sessions',
          data: {},
          options: Options(
            responseType: ResponseType.plain,  // JSON 파싱 비활성화
          ),
        );

        print('📥 [Status] ${response.statusCode}');
        print('📥 [Data] ${response.data}');

        if (response.statusCode == 200) {
          final sessionId = response.data.toString().trim();
          // 따옴표 제거 (혹시 "ses_xxx" 형태로 올 경우)
          return sessionId.replaceAll('"', '');
        }
      } on DioException catch (e) {
        print("❌ 세션 생성 실패: ${e.response?.statusCode} / ${e.response?.data}");
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

  // [Step 3] 입장권(Token) 받기 (실제 화상 스트림 연결용 WebSocket 주소 포함)
    Future<String?> getConnectionToken(String sessionId) async {
      try {
        final response = await _dio.post(
          "/openvidu/sessions/$sessionId/connections",
          options: Options(
            responseType: ResponseType.plain,  // 추가!
          ),
        );

        print('📥 [Token Status] ${response.statusCode}');
        print('📥 [Token Data] ${response.data}');

        if (response.statusCode == 200) {
          final token = response.data.toString().trim();
          // 따옴표 제거
          return token.replaceAll('"', '');
        }
      } catch (e) {
        print("❌ [OpenVidu] 토큰 발급 실패: $e");
      }
      return null;
  }
}
