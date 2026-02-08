import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_constants.dart';
import '../utils/jwt_decoder.dart';
import '../storage/storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      // ✅ [첨삭 1] 공통 헤더 추가: 서버와의 통신 규격을 명확히 함
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final storage = ref.watch(storageProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      // [1. 요청 전] 헤더에 토큰 삽입
      onRequest: (options, handler) async {
        // 일부 엔드포인트는 인증없이 호출되어야 합니다 (로그인/회원가입 등).
        const noAuthPaths = <String>{ApiConstants.login, ApiConstants.signup};

        // 요청 경로가 noAuthPaths에 포함되어 있지 않다면 토큰을 삽입합니다.
        final requestPath = options.path;
        final bool requiresAuth = !noAuthPaths.any(
              (p) => requestPath.contains(p),
        );

        if (requiresAuth) {
          final accessToken = await storage.read(key: 'accessToken');
          if (accessToken != null && accessToken.isNotEmpty) {
            print('🚀 API 호출: ${options.method} ${options.path}');
            print('🔑 토큰 (처음 30자): ${accessToken.substring(0, 30)}...');

            // ⭐ 토큰 정보 확인
            decodeJwtToken(accessToken);

            options.headers['Authorization'] = 'Bearer $accessToken';
          } else {
            print('⚠️ [AUTH] 토큰이 없습니다');
          }
        }

        return handler.next(options);
      },

      // [2. 에러 발생 시] 401 응답일 때만 로그아웃 처리
      onError: (DioException e, handler) async {
        // ✅ [첨삭 3] 500 에러 발생 시 서버 메시지 출력 (디버깅 필수)
        if (e.response?.statusCode == 500) {
          print('🔥 [SERVER 500] 서버 내부 오류 발생!');
          print('📝 [에러 바디]: ${e.response?.data}'); // 여기서 서버의 '진짜 이유' 확인 가능
        }

        // 401(Unauthorized) 에러 처리
        if (e.response?.statusCode == 401) {
          print('🚨 [AUTH] 토큰 만료(401). 세션을 종료합니다.');
          await storage.deleteAll();
          // TODO: UI 레이어에서 로그아웃 상태를 감지하여 로그인 화면으로 이동시키는 로직 필요
        }

        return handler.next(e);
      },
    ),
  );

  return dio;
});
