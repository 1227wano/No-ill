// lib/features/call/providers/call_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/services/call_service.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});

class CallNotifier extends StateNotifier<CallState> {
  final Ref ref;
  final _service = OpenViduService();

  CallNotifier(this.ref) : super(CallState());

  // 🎯 1. 렌더러 초기화 (내 화면이 바로 보이도록)
  Future<void> initRenderers() async {
    if (state.localRenderer != null) return;

    // 🎯 1. 카메라 및 마이크 권한 요청
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      final local = RTCVideoRenderer();
      final remote = RTCVideoRenderer();
      await local.initialize();
      await remote.initialize();

      // 🎯 2. 실제 내 카메라 스트림 가져오기
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'user', // 전면 카메라
        },
      };

      try {
        MediaStream stream = await navigator.mediaDevices.getUserMedia(
          mediaConstraints,
        );
        local.srcObject = stream; // 👈 내 렌더러에 스트림 주입!

        state = state.copyWith(localRenderer: local, remoteRenderer: remote);
        print("✅ 로컬 카메라 스트림 획득 성공");
      } catch (e) {
        print("❌ 카메라 스트림 획득 실패: $e");
      }
    } else {
      print("🚫 카메라/마이크 권한이 거부되었습니다.");
    }
  }

  // 📱 A. 보호자가 전화를 걸 때 (Caller)
  Future<void> startCall(String petId, String careName) async {
    // 🎯 2. 전화를 걸기 시작하자마자 내 카메라부터 켭니다 (UX 향상)
    await initRenderers();

    state = state.copyWith(
      status: CallStatus.calling,
      petId: petId,
      careName: careName,
    );

    try {
      final sessionId = await _service.createSession();
      if (sessionId != null) {
        final token = await _service.getConnectionToken(sessionId);
        if (token != null) {
          await _service.notifyCall(petId, sessionId);

          // 🎯 3. 실제 WebRTC 연결 로직이 여기에 들어와야 합니다.
          // _service.connectToSession(token, state.localRenderer);

          state = state.copyWith(
            status: CallStatus.connected,
            sessionId: sessionId,
            token: token,
          );
        }
      }
    } catch (e) {
      print("❌ 통화 시작 오류: $e");
      state = state.copyWith(status: CallStatus.idle);
    }
  }

  // 전화 수신
  void setIncomingCall(String sessionId, String petId, String careName) {
    state = state.copyWith(
      status: CallStatus.incoming,
      sessionId: sessionId,
      petId: petId,
      careName: careName,
    );

    // 통화 화면 진입 전 렌더러(카메라/마이크 뷰어) 초기화
    initRenderers();
  }

  // 🎯 4. 자원 해제 (매우 중요!)
  // 통화가 종료되거나 앱이 꺼질 때 카메라/마이크를 확실히 끕니다.
  @override
  void dispose() {
    state.localRenderer?.dispose();
    state.remoteRenderer?.dispose();
    super.dispose();
  }

  // 🎯 5. 통화 종료 로직 추가
  void endCall() {
    state.localRenderer?.srcObject = null;
    state.remoteRenderer?.srcObject = null;
    state = CallState(); // 상태 초기화
  }
}
