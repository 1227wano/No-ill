// 통화 상태 정의
// lib/features/call/models/call_state.dart
enum CallStatus { idle, calling, connected, incoming, ended }

class CallState {
  final CallStatus status;
  final String? sessionId;
  final String? token; // 오픈비두 세션 토큰
  final bool isMicOn;
  final bool isCameraOn;
  final String? callerName; // 💡 전화를 건 사람 이름을 띄우기 위해 추가하면 좋습니다.

  CallState({
    this.status = CallStatus.idle,
    this.sessionId,
    this.token,
    this.isMicOn = true,
    this.isCameraOn = true,
    this.callerName,
  });

  // 상태 변경을 위한 copyWith
  CallState copyWith({
    CallStatus? status,
    String? sessionId,
    String? token,
    bool? isMicOn,
    bool? isCameraOn,
    String? callerName,
  }) {
    return CallState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      isMicOn: isMicOn ?? this.isMicOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      callerName: callerName ?? this.callerName,
    );
  }
}
