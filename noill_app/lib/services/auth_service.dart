import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/services/fcm_service.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import '../models/auth_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider); // 인터셉터가 달린 공통 Dio 사용
  return AuthService(dio, ref);
});

class AuthService {
  // ✅ 수정: 직접 생성하지 않고 외부(Provider)에서 주입받습니다.
  // 이렇게 해야 dioProvider에 설정한 '토큰 자동 삽입' 인터셉터를 사용할 수 있습니다.
  final Dio _dio;
  final Ref _ref;

  AuthService(this._dio, this._ref);

  // [로그인]
  Future<LoginResponse> login(String id, String password) async {
    print("[API 요청 데이터] : $id / $password ");
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {"userId": id, "userPassword": password},
      );

      print("✅ 로그인 성공: ${response.data}");
      // 3. 로그인 성공 시 바로 FCM 등록 시도 (비동기로 실행)
      // 주의: 이 시점에 이미 Dio 인터셉터가 새 토큰을 인식할 수 있어야 함
      _registerFcmTokenAfterLogin();
      // 로그인 성공 처리 부분
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError("로그인", e);
      rethrow;
    }
  }

  // [회원가입]
  Future<CommonResponse> signUp(SignupRequest request) async {
    print("🚀 [POST] 회원가입 요청 데이터: ${request.toJson()}");

    try {
      final response = await _dio.post(
        ApiConstants.signup,
        data: request.toJson(),
      );

      print("✅ 회원가입 성공: ${response.data}");
      return CommonResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError("회원가입", e);

      rethrow;
    }
  }

  // [로그아웃]
  // 💡 주의: 이 함수는 서버에 로그아웃을 '통보'만 합니다.
  // 실제 기기의 토큰 삭제는 AuthProvider에서 처리해야 합니다.
  Future<CommonResponse> logout() async {
    print("🚀 [GET] 로그아웃 시도");
    try {
      final response = await _dio.post(ApiConstants.logout);
      return CommonResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError("로그아웃", e);
      rethrow;
    }
  }

  void _handleError(String functionName, DioException e) {
    print("❌ $functionName 실패");
    print("- 상태 코드: ${e.response?.statusCode}");
    print("- 에러 데이터: ${e.response?.data}");
    print("- 에러 메시지: ${e.message}");
  }

  // 별도 메서드로 분리하면 코드가 더 깔끔해집니다.
  Future<void> _registerFcmTokenAfterLogin() async {
    try {
      final fcmService = _ref.read(fcmServiceProvider);
      final token = await fcmService.getFcmToken();

      if (token != null) {
        await fcmService.sendTokenToServer(token);
        print("✅ [FCM] 로그인 후 자동 등록 완료");
      }
    } catch (e) {
      print("⚠️ [FCM] 로그인 후 등록 실패 (로그인에는 지장 없음): $e");
    }
  }
}
