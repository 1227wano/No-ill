// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 👈 추가
import 'package:dio/dio.dart';
import '../services/fcm_service.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';

final authServiceProvider = Provider((ref) => AuthService());

// 💡 보안 저장소 인스턴스 생성
const _storage = FlutterSecureStorage();

class AuthNotifier extends Notifier<AsyncValue<LoginData?>> {
  @override
  AsyncValue<LoginData?> build() {
    // 초기 상태는 데이터가 없는(null) 상태입니다.
    return const AsyncValue.data(null);
  }

  // 1. 로그인 로직
  Future<bool> login(String id, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(authServiceProvider).login(id, password);

      if (response.success && response.data != null) {
        // Debug log: 로그인 응답 확인
        // ignore: avoid_print
        print('AuthNotifier: login success, storing tokens');
        // 1. JWT 토큰을 기기에 안전하게 저장합니다.
        await _storage.write(
          key: 'accessToken',
          value: response.data!.accessToken,
        );
        await _storage.write(
          key: 'refreshToken',
          value: response.data!.refreshToken,
        );
        print(
          'AuthNotifier: tokens saved (accessToken length=${response.data!.accessToken.length ?? 0})',
        );
        // 2. FCM 토큰을 백엔드 서버로 전송합니다.
        _registerFcmToken(response.data!.accessToken);
        state = AsyncValue.data(response.data);
        return true;
      } else {
        // Debug log: 로그인 실패 원인 출력
        // ignore: avoid_print
        print('AuthNotifier: login failed - ${response.message}');
        state = AsyncValue.error(response.message, StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      // Debug log: 예외 발생
      // ignore: avoid_print
      print('AuthNotifier: login exception - $e');
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // [FCM 토큰 등록 내부 함수]
  Future<void> _registerFcmToken(String accessToken) async {
    try {
      final fcmService = ref.read(fcmServiceProvider);

      // 1. FCM 토큰 발급
      final token = await fcmService.getFcmToken();

      if (token != null) {
        // 2. 백엔드 전송 (협의된 규격 적용)
        await fcmService.sendTokenToServer(token, accessToken);

        // 3. 토큰 갱신 리스너 가동 (이미 로그인 상태이므로 리스너 등록)
        fcmService.listenToTokenRefresh(accessToken);
        print('🚀 [AuthNotifier] FCM 등록 및 리스너 가동 완료');
      }
    } catch (e) {
      // 알림 등록 실패가 로그인을 방해해서는 안 되므로 에러 로그만 남깁니다.
      print('⚠️ [AuthNotifier] FCM 등록 중 비치명적 에러: $e');
    }
  }

  // 2. 회원가입 로직
  Future<bool> signUp(SignupRequest request) async {
    state = const AsyncValue.loading();
    try {
      // 💡 여기서 전달되는 request.pets는 이미 []로 처리되어 있겠죠?
      final response = await ref.read(authServiceProvider).signUp(request);
      state = const AsyncValue.data(null);
      return response.success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // 3. 로그아웃 로직
  Future<void> logout() async {
    try {
      // 서버 로그아웃 호출
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      // 서버 에러와 무관하게 클라이언트는 청소합니다.
    } finally {
      // ✅ [핵심] 저장된 모든 토큰을 삭제합니다.
      await _storage.deleteAll();
      state = const AsyncValue.data(null);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<LoginData?>>(
  () => AuthNotifier(),
);
