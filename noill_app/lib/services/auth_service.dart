import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import '../models/auth_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider); // 인터셉터가 달린 공통 Dio 사용
  return AuthService(dio);
});

class AuthService {
  // ✅ 수정: 직접 생성하지 않고 외부(Provider)에서 주입받습니다.
  // 이렇게 해야 dioProvider에 설정한 '토큰 자동 삽입' 인터셉터를 사용할 수 있습니다.
  final Dio _dio;

  AuthService(this._dio);

  // [로그인]
  Future<LoginResponse> login(String id, String password) async {
    print("[API 요청 데이터] : $id / $password ");
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {"userId": id, "userPassword": password},
      );

      print("✅ 로그인 성공: ${response.data}");
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
}
