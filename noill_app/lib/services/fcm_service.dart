import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_constants.dart';

final fcmServiceProvider = Provider((ref) => FcmService());

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  late final Dio _dio;

  FcmService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    print('🚀 [FCM SERVICE] 초기화 완료');
  }

  /// [FCM 토큰 가져오기]
  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('✅ [FCM] 토큰 획득 성공: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      print('❌ [FCM] 토큰 발급 실패: $e');
      return null;
    }
  }

  /// [백엔드 서버로 토큰 전송]
  /// accessToken이 필요하므로 로그인 후 사용
  Future<bool> sendTokenToServer(String fcmToken, String accessToken) async {
    try {
      print('🚀 [FCM] 서버로 토큰 전송 중...');

      final response = await _dio.post(
        '/notifications/token',
        data: {'token': fcmToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] 토큰 전송 성공');
        return true;
      } else {
        print('❌ [FCM] 토큰 전송 실패 - 상태코드: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('❌ [FCM] 서버 전송 실패: ${e.message}');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 응답: ${e.response?.data}');
      return false;
    } catch (e) {
      print('❌ [FCM] 예상치 못한 오류: $e');
      return false;
    }
  }

  /// [토큰 갱신 리스너]
  /// 토큰이 갱신될 때마다 새 토큰을 서버로 전송
  void listenToTokenRefresh(String accessToken) {
    print('🔔 [FCM] 토큰 갱신 리스너 시작');

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        print('🔄 [FCM] 토큰 갱신됨: ${newToken.substring(0, 20)}...');
        final success = await sendTokenToServer(newToken, accessToken);
        if (!success) {
          print('⚠️ [FCM] 갱신된 토큰 전송 재시도 필요');
        }
      },
      onError: (error) {
        print('❌ [FCM] 토큰 갱신 리스너 에러: $error');
      },
    );
  }

  /// [포그라운드 메시지 리스너]
  /// 앱이 실행 중일 때 메시지 수신
  void listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        print('💬 [FCM] 포그라운드 메시지 수신');
        print('   - 제목: ${message.notification?.title}');
        print('   - 내용: ${message.notification?.body}');
        print('   - 데이터: ${message.data}');
      },
      onError: (error) {
        print('❌ [FCM] 포그라운드 메시지 리스너 에러: $error');
      },
    );
  }

  /// [초기 메시지 확인]
  /// 앱이 종료된 상태에서 수신한 메시지 확인
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📧 [FCM] 초기 메시지 발견');
        print('   - 제목: ${initialMessage.notification?.title}');
      }
      return initialMessage;
    } catch (e) {
      print('❌ [FCM] 초기 메시지 확인 실패: $e');
      return null;
    }
  }
}
