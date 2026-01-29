import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // kDebugMode 사용을 위해 필요

final fcmServiceProvider = Provider((ref) => FcmService());

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 1. 테스트용과 실전용 주소를 상수로 정의합니다.
  static const String _testUrl = 'http://localhost:8080';
  static const String _prodUrl = 'https://i14a301.p.ssafy.io';

  late final Dio _dio;

  FcmService() {
    // 2. 현재 앱이 디버그 모드인지 배포 모드인지에 따라 주소를 결정합니다.
    final String selectedUrl = kDebugMode ? _testUrl : _prodUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: selectedUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    print('🚀 [FCM SERVICE] 현재 연결된 서버: $selectedUrl');
  }

  /// [FCM 토큰 가져오기]
  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      return token;
    } catch (e) {
      print('❌ [FCM] 토큰 발급 실패: $e');
      return null;
    }
  }

  /// [백엔드 서버로 토큰 전송]
  Future<bool> sendTokenToServer(String fcmToken, String jwt) async {
    try {
      final response = await _dio.post(
        '/api/notifications/token',
        data: {'token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ [FCM] 서버 전송 실패: $e');
      return false;
    }
  }

  // 3. 그리고 방금 추가한 리스너!
  void listenToTokenRefresh(String jwt) {
    _messaging.onTokenRefresh.listen((newToken) async {
      await sendTokenToServer(newToken, jwt);
    });
  }
}
