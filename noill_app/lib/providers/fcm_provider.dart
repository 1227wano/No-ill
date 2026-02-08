// lib/providers/fcm_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_provider.dart'; // dio 프로바이더
import '../core/utils/result.dart';
import '../services/fcm_service.dart'; // 수정했던 FcmService(dio)

final fcmProvider = Provider((ref) {
  // 💡 [주의] 저번 턴에 수정했던 것처럼 dio를 주입해야 에러가 안 납니다!
  final dio = ref.read(dioProvider);
  final service = FcmService(dio, ref);

  return FcmLogic(ref, service);
});

class FcmLogic {
  final Ref ref;
  final FcmService service;

  FcmLogic(this.ref, this.service);

  // 로그인 후 호출할 통합 초기화 함수
  Future<void> setupAfterLogin(String accessToken) async {
    final token = await service.getFcmToken();
    if (token != null) {
      final result = await service.sendTokenToServer(token);
      if (result.isSuccess) {
        await service.initialize(); // 리스너 등록 등 포함
      }
    }
  }
}
