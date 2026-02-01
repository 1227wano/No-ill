import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_constants.dart';
import '../storage/storage_provider.dart'; // 👈 공통 저장소 사용

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
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
            print('🚀 API 호출에 쓰이는 토큰: $accessToken'); // 여기에 추가!
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        return handler.next(options);
      },

      // [2. 에러 발생 시] 401 응답일 때만 로그아웃 처리
      onError: (DioException e, handler) async {
        // ✅ [수정] 401(Unauthorized) 에러인 경우만 체크
        if (e.response?.statusCode == 401) {
          print('🚨 [AUTH] 토큰 만료(401) 감지. 세션을 종료합니다.');

          // 저장소 데이터를 삭제하여 다음 앱 실행 시 로그인 화면으로 가게 함
          await storage.deleteAll();

          // 주의: 여기서 직접 authProvider를 read하면 순환 참조가 생길 수 있으므로
          // 필요한 경우에만 최소한으로 호출하거나, UI 레이어에서 상태 감시 후 이동 권장
        }

        return handler.next(e);
      },
    ),
  );

  return dio;
});
