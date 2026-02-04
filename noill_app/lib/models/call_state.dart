// 통화 상태 정의
import 'package:flutter_webrtc/flutter_webrtc.dart'; // 추가

enum CallStatus { idle, calling, connected, incoming, ended }

class CallState {
  final CallStatus status;
  final String? sessionId;
  final String? token;
  final bool isMicOn;
  final bool isCameraOn;

  // 🎯 추가된 필드: 누구와 통화 중인지 식별하기 위함
  final String? petId;
  final String? careName;
  final RTCVideoRenderer? localRenderer; // 내 화면
  final RTCVideoRenderer? remoteRenderer; // 상대방(어르신) 화면

  CallState({
    this.status = CallStatus.idle,
    this.sessionId,
    this.token,
    this.isMicOn = true,
    this.isCameraOn = true,
    this.petId, // 🎯 추가
    this.careName, // 🎯 추가
    this.localRenderer,
    this.remoteRenderer,
  });

  // 상태 변경을 위한 copyWith
  CallState copyWith({
    CallStatus? status,
    String? sessionId,
    String? token,
    bool? isMicOn,
    bool? isCameraOn,
    String? petId, // 🎯 추가
    String? careName, // 🎯 추가
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
  }) {
    return CallState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      isMicOn: isMicOn ?? this.isMicOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      petId: petId ?? this.petId, // 🎯 추가
      careName: careName ?? this.careName, // 🎯 추가
      localRenderer: localRenderer ?? this.localRenderer,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
    );
  }
}
