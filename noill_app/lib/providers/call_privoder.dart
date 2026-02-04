// lib/features/call/providers/call_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/services/openvidu_service.dart';
import 'package:noill_app/core/network/dio_provider.dart';

import 'package:permission_handler/permission_handler.dart';

// OpenViduService를 dioProvider로 주입
final openViduServiceProvider = Provider<OpenViduService>((ref) {
  final dio = ref.read(dioProvider);
  return OpenViduService(dio);
});

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});

class CallNotifier extends StateNotifier<CallState> {
  final Ref ref;
  OpenViduService? _serviceInstance;

  OpenViduService get _service {
    _serviceInstance ??= ref.read(openViduServiceProvider);
    return _serviceInstance!;
  }

  CallNotifier(this.ref) : super(CallState());

  // 렌더러 초기화 (내 화면이 바로 보이도록)
  Future<void> initRenderers() async {
    if (state.localRenderer != null) return;

    // 카메라 및 마이크 권한 요청
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

      // 실제 내 카메라 스트림 가져오기
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
        local.srcObject = stream;

        state = state.copyWith(localRenderer: local, remoteRenderer: remote);
        print("✅ 로컬 카메라 스트림 획득 성공");
      } catch (e) {
        print("❌ 카메라 스트림 획득 실패: $e");
      }
    } else {
      print("🚫 카메라/마이크 권한이 거부되었습니다.");
    }
  }

  // 보호자가 전화를 걸 때 (Caller)
  Future<void> startCall(String petId, String careName) async {
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

  // 자원 해제
  @override
  void dispose() {
    state.localRenderer?.dispose();
    state.remoteRenderer?.dispose();
    super.dispose();
  }

  // 통화 종료
  void endCall() {
    state.localRenderer?.srcObject = null;
    state.remoteRenderer?.srcObject = null;
    state = CallState(); // 상태 초기화
  }
}
