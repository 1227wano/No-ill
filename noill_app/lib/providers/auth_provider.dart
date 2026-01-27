// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';

final authServiceProvider = Provider((ref) => AuthService());

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
        state = AsyncValue.data(response.data);
        // TODO: 여기서 SecureStorage에 accessToken 저장 로직을 추가하세요.
        return true;
      } else {
        state = AsyncValue.error(response.message, StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // 2. 회원가입 로직 (추가됨)
  Future<bool> signUp(SignupRequest request) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(authServiceProvider).signUp(request);

      // 가입 후엔 다시 빈 데이터 상태로 되돌려 로그인을 유도합니다.
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
      // 로그아웃은 서버 응답과 관계없이 클라이언트 상태를 먼저 비우는 것이 UX상 좋습니다.
    } finally {
      // 로컬 토큰 삭제 로직을 여기에 추가하세요.
      state = const AsyncValue.data(null);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<LoginData?>>(
  () => AuthNotifier(),
);
