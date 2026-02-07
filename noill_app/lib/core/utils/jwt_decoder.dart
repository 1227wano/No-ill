// lib/core/utils/jwt_decoder.dart

import 'dart:convert';

void decodeJwtToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      print('❌ [JWT] 잘못된 토큰 형식');
      return;
    }

    // Payload 디코딩
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(decoded);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 [JWT Token 정보]');
    print('📋 전체 Payload: $payloadMap');
    print('👤 사용자 ID (sub): ${payloadMap['sub']}');

    // Role/Authority 확인
    final roles = payloadMap['roles'] ?? payloadMap['authorities'] ?? payloadMap['role'];
    print('🔑 권한 (roles): $roles');

    // 만료 시간 확인
    if (payloadMap['iat'] != null) {
      final iat = payloadMap['iat'];
      final iatDate = DateTime.fromMillisecondsSinceEpoch(iat * 1000);
      print('⏰ 발급 시간 (iat): $iatDate');
    }

    if (payloadMap['exp'] != null) {
      final exp = payloadMap['exp'];
      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      print('⏰ 만료 시간 (exp): $expDate');
      print('⏰ 현재 시간: $now');

      final diff = expDate.difference(now);
      if (diff.isNegative) {
        print('❌ 토큰이 ${diff.inMinutes.abs()}분 전에 만료되었습니다!');
      } else {
        print('✅ 토큰이 유효합니다 (만료까지 ${diff.inHours}시간 ${diff.inMinutes % 60}분 남음)');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (e) {
    print('❌ [JWT] 디코딩 실패: $e');
  }
}
