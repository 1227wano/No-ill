import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../models/auth_models.dart';

class AuthService {
  // 💡 BaseOptions에 타임아웃을 설정하여 무한 대기를 방지합니다.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // [로그인]
  Future<LoginResponse> login(String id, String password) async {
    print("🚀 [POST] 로그인 시도: $id");
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          "userId": id, // 명세서 규격 준수
          "userPassword": password, // 명세서 규격 준수
        },
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
    // 💡 이제 request.toJson()에는 우리가 추가한 'pets' 리스트가 자동으로 포함됩니다.
    print("🚀 [POST] 회원가입 요청 데이터: ${request.toJson()}");

    try {
      final response = await _dio.post(
        ApiConstants.signup, // 보통 "/auth/signup"
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
  Future<CommonResponse> logout() async {
    print("🚀 [GET] 로그아웃 시도");
    try {
      final response = await _dio.get(ApiConstants.logout);
      return CommonResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError("로그아웃", e);
      rethrow;
    }
  }

  // 💡 공통 에러 핸들러: 기획자님이 디버깅하기 편하도록 상세 로그를 찍습니다.
  void _handleError(String functionName, DioException e) {
    print("❌ $functionName 실패");
    print("- 상태 코드: ${e.response?.statusCode}");
    print("- 에러 데이터: ${e.response?.data}");
    print("- 에러 메시지: ${e.message}");
  }
}
