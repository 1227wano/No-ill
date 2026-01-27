// 인증 서비스
// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../models/auth_models.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  // 로그인
  Future<LoginResponse> login(String id, String password) async {
    print("로그인 시도 중: $id");
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {"userId": id, "userPassword": password},
      );
      print("서버 응답 성공: ${response.data}"); // 응답 데이터 확인
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("서버 응답 데이터: ${e.response?.statusCode} - ${e.response?.data}");
      rethrow; // 네트워크 오류 등 다른 예외는 다시 던짐
    }
  }

  // 회원가입
  Future<CommonResponse> signUp(SignupRequest request) async {
    // 1. 요청 데이터 로그
    print("회원가입 요청 데이터: ${request.toJson()}");

    try {
      final response = await _dio.post(
        ApiConstants.signup,
        data: request.toJson(),
      );
      print("서버 응답 성공: ${response.data}"); // 응답 데이터 확인
      return CommonResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("서버 응답 데이터: ${e.response?.statusCode} - ${e.response?.data}");
      rethrow; // 네트워크 오류 등 다른 예외는 다시 던짐
    }
  }

  // 로그아웃
  Future<CommonResponse> logout() async {
    final response = await _dio.get(ApiConstants.logout); // 명세에 따라 post/get 조절
    return CommonResponse.fromJson(response.data);
  }
}
