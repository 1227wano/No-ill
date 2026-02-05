import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/services/openvidu_service.dart';
import 'package:noill_app/core/network/dio_provider.dart';

import 'package:openvidu_flutter/utils/session.dart';
import 'package:openvidu_flutter/participant/local_participant.dart';
import 'package:openvidu_flutter/utils/custom_websocket.dart';

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

  /// OpenVidu 서버에 WebRTC 연결을 수립합니다.
  Future<void> _connectToOpenVidu(String sessionId, String token) async {
    try {
      // 1. Session 객체 생성
      final session = Session(sessionId, token);

      // 2. 이벤트 핸들러 등록 (원격 참가자 입장/퇴장/스트림 변경 시 UI 갱신)
      session.onNotifySetRemoteMediaStream = (String connectionId) {
        print('📹 [OpenVidu] 원격 스트림 수신: $connectionId');
        _refreshState();
      };
      session.onAddRemoteParticipant = (String connectionId) {
        print('👤 [OpenVidu] 원격 참가자 입장: $connectionId');
        _refreshState();
      };
      session.onRemoveRemoteParticipant = (String connectionId) {
        print('👋 [OpenVidu] 원격 참가자 퇴장: $connectionId');
        _refreshState();
      };

      // 3. 메시지 스트림 구독
      session.messageStream.listen((_) => _refreshState());

      // 4. 로컬 참가자 생성 및 카메라 시작
      final localParticipant = LocalParticipant('user', session);
      await localParticipant.renderer.initialize();
      await localParticipant.startLocalCamera();
      print('✅ [OpenVidu] 로컬 카메라 시작 완료');

      // 5. WebSocket 연결 (OpenVidu 시그널링 서버)
      final webSocket = CustomWebSocket(
        session,
        customClient: HttpClient()
          ..badCertificateCallback = (X509Certificate cert, String host, int port) => true,
      );
      webSocket.onErrorEvent = (error) {
        print('❌ [OpenVidu] WebSocket 에러: $error');
      };
      webSocket.connect();
      session.setWebSocket(webSocket);
      print('✅ [OpenVidu] WebSocket 연결 완료');

      // 6. 상태 업데이트
      state = state.copyWith(
        session: session,
        status: CallStatus.connected,
      );
    } catch (e) {
      print('❌ [OpenVidu] 연결 실패: $e');
      state = state.copyWith(status: CallStatus.ended);
    }
  }

  /// state를 다시 emit하여 UI를 갱신합니다.
  void _refreshState() {
    if (!mounted) return;
    state = state.copyWith();
  }

  /// 보호자가 전화를 걸 때 (Caller)
  Future<void> startCall(String petId, String careName) async {
    state = state.copyWith(
      status: CallStatus.calling,
      petId: petId,
      careName: careName,
    );

    try {
      // 1. 세션 생성
      final sessionId = await _service.createSession();
      if (sessionId == null) {
        print('❌ [Call] 세션 생성 실패');
        state = state.copyWith(status: CallStatus.ended);
        return;
      }
      print('✅ [Call] 세션 생성: $sessionId');

      // 2. 토큰 발급
      final token = await _service.getConnectionToken(sessionId);
      if (token == null) {
        print('❌ [Call] 토큰 발급 실패');
        state = state.copyWith(status: CallStatus.ended);
        return;
      }
      print('✅ [Call] 토큰 발급 완료');

      state = state.copyWith(sessionId: sessionId, token: token);

      // 3. 상대방에게 FCM 알림
      await _service.notifyCall(petId, sessionId);
      print('✅ [Call] 상대방 호출 완료');

      // 4. OpenVidu WebRTC 연결
      await _connectToOpenVidu(sessionId, token);
    } catch (e) {
      print('❌ [Call] 통화 시작 오류: $e');
      state = state.copyWith(status: CallStatus.ended);
    }
  }

  /// 수신 측에서 전화를 받을 때 (Callee - FCM 수신 후)
  Future<void> acceptIncomingCall() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      print('❌ [Call] sessionId 없음 - 수락 불가');
      return;
    }

    try {
      // 토큰 발급
      final token = await _service.getConnectionToken(sessionId);
      if (token == null) {
        print('❌ [Call] 수신 토큰 발급 실패');
        state = state.copyWith(status: CallStatus.ended);
        return;
      }
      print('✅ [Call] 수신 토큰 발급 완료');

      state = state.copyWith(token: token);

      // OpenVidu WebRTC 연결
      await _connectToOpenVidu(sessionId, token);
    } catch (e) {
      print('❌ [Call] 수신 연결 오류: $e');
      state = state.copyWith(status: CallStatus.ended);
    }
  }

  /// FCM으로 수신 전화 정보 설정
  void setIncomingCall(String sessionId, String petId, String careName) {
    state = state.copyWith(
      status: CallStatus.incoming,
      sessionId: sessionId,
      petId: petId,
      careName: careName,
    );
  }

  /// 통화 종료 및 자원 해제
  void endCall() {
    try {
      state.session?.leaveSession();
      print('✅ [Call] 세션 종료');
    } catch (e) {
      print('⚠️ [Call] 세션 종료 중 오류: $e');
    }
    state = CallState();
  }

  /// 마이크 토글
  void toggleAudio() {
    state.session?.localToggleAudio();
    _refreshState();
  }

  /// 카메라 토글
  void toggleVideo() {
    state.session?.localToggleVideo();
    _refreshState();
  }

  /// 카메라 전환 (전면/후면)
  void switchCamera() {
    state.session?.localParticipant?.switchCamera();
    _refreshState();
  }
}
