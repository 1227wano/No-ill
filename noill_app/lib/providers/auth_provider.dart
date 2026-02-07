// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../core/storage/storage_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import '../core/exceptions/app_exception.dart';

// ═══════════════════════════════════════════════════════════════════════
// 1. 인증 상태 정의
// ═══════════════════════════════════════════════════════════════════════

enum AuthStatus {
  initial,          // 초기 상태
  loading,          // 로딩 중
  authenticated,    // 인증됨
  unauthenticated,  // 미인증
  error,            // 에러
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final LoginData? userData;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.userData,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(LoginData userData) => AuthState(
    status: AuthStatus.authenticated,
    userData: userData,
  );

  factory AuthState.unauthenticated() => const AuthState(
    status: AuthStatus.unauthenticated,
  );

  factory AuthState.error(String message) => AuthState(
    status: AuthStatus.error,
    errorMessage: message,
  );

  // ✅ 도우미 Getter
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;

  // ✅ copyWith (상태 업데이트용)
  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    LoginData? userData,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userData: userData ?? this.userData,
    );
  }

  @override
  String toString() => 'AuthState(status: $status, userData: ${userData?.userName})';
}

// ═══════════════════════════════════════════════════════════════════════
// 2. AuthNotifier 정의
// ═══════════════════════════════════════════════════════════════════════

class AuthNotifier extends Notifier<AuthState> {
  final _logger = AppLogger('AuthNotifier');

  @override
  AuthState build() {
    // 앱 시작 시 자동으로 인증 상태 체크
    checkAuthStatus();
    return AuthState.initial();
  }

  /// [상태 점검] 저장소의 토큰으로 자동 로그인 확인
  Future<void> checkAuthStatus() async {
    try {
      _logger.info('인증 상태 확인 시작');

      final storage = ref.read(storageProvider);
      final token = await storage.read(key: 'accessToken');
      final name = await storage.read(key: 'userName');

      if (token != null && token.isNotEmpty) {
        _logger.info('저장된 토큰 발견 - 자동 로그인');

        state = AuthState.authenticated(
          LoginData(
            accessToken: token,
            refreshToken: '',
            userName: name ?? '사용자',
          ),
        );
      } else {
        _logger.info('저장된 토큰 없음 - 미인증 상태');
        state = AuthState.unauthenticated();
      }
    } catch (e, stackTrace) {
      _logger.error('인증 상태 확인 실패', e, stackTrace);
      state = AuthState.unauthenticated();
    }
  }

  /// [로그인]
  Future<bool> login(String id, String password) async {
    try {
      _logger.info('로그인 시도: $id');
      state = AuthState.loading();

      // ⭐ Result 패턴 사용
      final result = await ref.read(authServiceProvider).login(id, password);

      return result.fold(
        // ✅ 성공
        onSuccess: (response) async {
          if (response.success && response.data != null) {
            _logger.info('로그인 성공: ${response.data!.userName}');

            // 토큰 저장
            final storage = ref.read(storageProvider);
            await storage.write(
              key: 'accessToken',
              value: response.data!.accessToken,
            );
            await storage.write(
              key: 'userName',
              value: response.data!.userName,
            );

            // 상태 업데이트
            state = AuthState.authenticated(response.data!);
            return true;
          } else {
            _logger.warning('로그인 응답이 올바르지 않음');
            state = AuthState.error('로그인에 실패했습니다');
            return false;
          }
        },

        // ❌ 실패
        onFailure: (exception) {
          _logger.error('로그인 실패: ${exception.message}');
          state = AuthState.error(_getErrorMessage(exception));
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 로그인 에러', e, stackTrace);
      state = AuthState.error('로그인 중 오류가 발생했습니다');
      return false;
    }
  }

  /// [회원가입]
  Future<bool> signUp(SignupRequest request) async {
    try {
      _logger.info('회원가입 시도: ${request.userId}');
      state = AuthState.loading();

      // ⭐ Result 패턴 사용
      final result = await ref.read(authServiceProvider).signUp(request);

      return result.fold(
        // ✅ 성공
        onSuccess: (response) {
          _logger.info('회원가입 성공');
          state = AuthState.unauthenticated();
          return true;
        },

        // ❌ 실패
        onFailure: (exception) {
          _logger.error('회원가입 실패: ${exception.message}');
          state = AuthState.error(_getErrorMessage(exception));
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 회원가입 에러', e, stackTrace);
      state = AuthState.error('회원가입 중 오류가 발생했습니다');
      return false;
    }
  }

  /// [로그아웃]
  Future<void> logout() async {
    try {
      _logger.info('로그아웃 시도');

      // 1. 서버에 로그아웃 통보 (실패해도 진행)
      final result = await ref.read(authServiceProvider).logout();
      result.fold(
        onSuccess: (_) => _logger.info('서버 로그아웃 성공'),
        onFailure: (e) => _logger.warning('서버 로그아웃 실패 (무시): ${e.message}'),
      );
    } catch (e) {
      _logger.warning('서버 로그아웃 실패 (무시): $e');
    } finally {
      // 2. 로컬 저장소 완전 삭제
      await ref.read(storageProvider).deleteAll();
      _logger.info('로컬 데이터 삭제 완료');

      // 3. 상태 초기화
      state = AuthState.unauthenticated();
      _logger.info('로그아웃 완료');
    }
  }

  /// [에러 메시지 변환]
  /// AppException을 사용자 친화적인 메시지로 변환
  String _getErrorMessage(AppException exception) {
    // 이미 exception.message가 사용자 친화적이므로 그대로 사용
    return exception.message;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. Provider 선언
// ═══════════════════════════════════════════════════════════════════════

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// ═══════════════════════════════════════════════════════════════════════
// 4. 편의 Provider들
// ═══════════════════════════════════════════════════════════════════════

/// 현재 로그인한 사용자 정보
final currentUserProvider = Provider<LoginData?>((ref) {
  return ref.watch(authProvider).userData;
});

/// 로그인 여부
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// 로딩 여부
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});
