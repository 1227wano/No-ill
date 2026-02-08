// lib/models/call_state.dart

import 'package:openvidu_flutter/utils/session.dart';

enum CallStatus {
  idle,       // 대기 중
  calling,    // 발신 중
  connecting, // 연결 중
  incoming,   // 수신 중
  connected,  // 연결됨
  ended,      // 종료됨
}

class CallState {
  final CallStatus status;
  final String? sessionId;
  final String? token;
  final String? petId;
  final String? careName;
  final Session? session;
  final String? errorMessage;

  CallState({
    this.status = CallStatus.idle,
    this.sessionId,
    this.token,
    this.petId,
    this.careName,
    this.session,
    this.errorMessage,
  });

  CallState copyWith({
    CallStatus? status,
    String? sessionId,
    String? token,
    String? petId,
    String? careName,
    Session? session,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      petId: petId ?? this.petId,
      careName: careName ?? this.careName,
      session: session ?? this.session,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
