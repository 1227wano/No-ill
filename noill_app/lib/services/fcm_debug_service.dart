// lib/services/fcm_debug_service.dart
// FCM 디버깅 및 테스트용 서비스

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmDebugService {
  static const _storage = FlutterSecureStorage();

  /// [1] 저장된 accessToken 출력 (로그인 여부 확인)
  static Future<String?> getStoredAccessToken() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        print('✅ [DEBUG] AccessToken 발견: ${token.substring(0, 30)}...');
        return token;
      } else {
        print('❌ [DEBUG] AccessToken 없음 - 로그인이 필요합니다');
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] AccessToken 읽기 실패: $e');
      return null;
    }
  }

  /// [2] 현재 FCM 토큰 출력
  static Future<void> printCurrentFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('✅ [DEBUG] 현재 FCM Token: $token');
        print('   길이: ${token.length}');
      } else {
        print('❌ [DEBUG] FCM 토큰이 없습니다 - 권한을 요청하세요');
      }
    } catch (e) {
      print('❌ [DEBUG] FCM 토큰 조회 실패: $e');
    }
  }

  /// [3] 저장된 모든 보안 저장소 키 확인 (디버깅용)
  static Future<void> printAllStoredKeys() async {
    try {
      final keys = await _storage.readAll();
      print('✅ [DEBUG] 저장된 모든 키:');
      keys.forEach((key, value) {
        final displayValue = value.length > 50
            ? '${value.substring(0, 50)}...'
            : value;
        print('   $key: $displayValue');
      });
    } catch (e) {
      print('❌ [DEBUG] 저장소 읽기 실패: $e');
    }
  }

  /// [4] 로그인 상태 종합 진단
  static Future<void> diagnoseLoginStatus() async {
    print('\n📊 [DEBUG] === FCM 로그인 상태 진단 시작 ===');

    await getStoredAccessToken();
  }

  /// [5] 토큰 저장소 초기화 (테스트용)
  static Future<void> clearAllTokens() async {
    try {
      await _storage.deleteAll();
      print('✅ [DEBUG] 모든 토큰이 삭제되었습니다');
    } catch (e) {
      print('❌ [DEBUG] 토큰 삭제 실패: $e');
    }
  }

  /// [6] 수동으로 토큰 저장 (테스트용)
  static Future<void> saveTestToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('✅ [DEBUG] 테스트 토큰 저장: $key=$value');
    } catch (e) {
      print('❌ [DEBUG] 토큰 저장 실패: $e');
    }
  }
}
