// lib/features/call/providers/call_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/services/call_service.dart';

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});

class CallNotifier extends StateNotifier<CallState> {
  final Ref ref;
  final _service = OpenViduService();

  CallNotifier(this.ref) : super(CallState());

  // 📱 A. 보호자가 전화를 걸 때 (Caller)
  Future<void> startCall(String petId) async {
    state = state.copyWith(status: CallStatus.calling); // '연결 중' 상태

    // 1. 세션 생성 -> 2. 토큰 획득 -> 3. 디스플레이 알림
    final sessionId = await _service.createSession();
    if (sessionId != null) {
      final token = await _service.getConnectionToken(sessionId);
      if (token != null) {
        await _service.notifyCall(petId, sessionId);
        // SDK 연결 로직 (connect & publish) 호출 후 상태 변경
        state = state.copyWith(
          status: CallStatus.connected,
          sessionId: sessionId,
          token: token,
        );
      }
    }
  }

  // 📺 B. 로봇이 전화를 수신했을 때 (Receiver)
  void setIncomingCall(String sessionId) {
    state = state.copyWith(status: CallStatus.incoming, sessionId: sessionId);
  }

  // 📺 B. 로봇이 수락 버튼을 눌렀을 때
  Future<void> acceptCall() async {
    if (state.sessionId == null) return;

    final token = await _service.getConnectionToken(state.sessionId!);
    if (token != null) {
      // SDK 연결 로직 실행 후
      state = state.copyWith(status: CallStatus.connected, token: token);
    }
  }
}
