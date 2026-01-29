import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_constants.dart';
import '../../providers/auth_provider.dart'; // providers 폴더는 UI 상 변하는 데이터, dio_provider는 전체 통신/인프라에 해당하므로 별도 관리

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // 1. 기본 설정 (BaseUrl 등)
  dio.options.baseUrl = dotenv.env['API_BASE_URL'] ?? ApiConstants.baseUrl;
  dio.options.connectTimeout = const Duration(seconds: 5);

  // 2. 인터셉터 추가
  dio.interceptors.add(
    InterceptorsWrapper(
      // [요청 전] 모든 요청에 토큰을 자동으로 실어 보냄
      // [진짜 코드]
      onRequest: (options, handler) async {
        // 여기에 저장소에서 토큰을 읽어와서 헤더에 넣는 로직을 추가할 수 있습니다.
        return handler.next(options);
      },

      // [에러 발생 시] 서버가 401 에러를 던지면 낚아챔
      onError: (DioException e, handler) async {
        // if (e.response?.statusCode == 401) {
        print('🚨 [AUTH] 토큰 만료 (401). 자동 로그아웃을 실행합니다.');

        // 🔥 핵심: authProvider의 로그아웃 로직을 호출
        // 이 함수 안에서 토큰 삭제와 상태 초기화가 한 번에 일어납니다.
        await ref.read(authProvider.notifier).logout();

        // 참고: 여기서 바로 로그인 화면으로 이동시키는 코드를 넣거나,
        // main.dart에서 authProvider의 상태 변화를 감시해 이동시킬 수 있습니다.
        // }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
