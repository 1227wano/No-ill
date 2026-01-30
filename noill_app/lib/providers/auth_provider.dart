import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../core/storage/storage_provider.dart';

// 1. 인증 상태 정의 (상태에 따라 UI가 자동으로 변합니다)
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({required this.status, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  // ✅ UI에서 쉽게 쓰도록 도우미 변수(Getter) 추가
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// 2. AuthNotifier 정의 (로그인/로그아웃 로직 담당)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 앱이 실행될 때 자동으로 로그인 상태를 점검합니다.
    checkAuthStatus();
    return AuthState.initial();
  }

  /// [상태 점검] 저장소에 토큰이 있는지 확인하여 자동 로그인 처리
  Future<void> checkAuthStatus() async {
    final storage = ref.read(storageProvider);
    final token = await storage.read(key: 'accessToken');

    if (token != null) {
      state = const AuthState(status: AuthStatus.authenticated);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// [로그인] 성공 시 토큰을 저장하고 상태를 변경합니다.
  Future<void> login(String id, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await ref.read(authServiceProvider).login(id, password);

      // 기기 저장소에 토큰 저장
      final storage = ref.read(storageProvider);
      await storage.write(
        key: 'accessToken',
        value: response.data?.accessToken ?? '',
      );
      await storage.write(
        key: 'refreshToken',
        value: response.data?.refreshToken ?? '',
      );

      state = const AuthState(status: AuthStatus.authenticated);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<bool> signUp(SignupRequest request) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await ref.read(authServiceProvider).signUp(request);
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      ); // 가입 후 로그인 유도
      return true; // 성공 시 true 반환
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
      return false; // 실패 시 false 반환
    }
  }

  /// [로그아웃] 서버 통보 후 저장소를 비워 자동 로그인을 해제합니다.
  Future<void> logout() async {
    try {
      // 1. 서버에 로그아웃 통보 (실패해도 진행)
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      print("서버 로그아웃 통보 실패: $e");
    } finally {
      // 2. 핵심: 기기 저장소 데이터 완전 삭제
      await ref.read(storageProvider).deleteAll();

      // 3. 상태 초기화 -> UI가 이를 감지해 로그인 화면으로 이동
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

// 3. 전역에서 접근 가능한 authProvider 선언
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
