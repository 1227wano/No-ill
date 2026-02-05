import 'package:openvidu_flutter/utils/session.dart';

enum CallStatus { idle, calling, connected, incoming, ended }

class CallState {
  final CallStatus status;
  final String? sessionId;
  final String? token;
  final String? petId;
  final String? careName;
  final Session? session;

  CallState({
    this.status = CallStatus.idle,
    this.sessionId,
    this.token,
    this.petId,
    this.careName,
    this.session,
  });

  CallState copyWith({
    CallStatus? status,
    String? sessionId,
    String? token,
    String? petId,
    String? careName,
    Session? session,
  }) {
    return CallState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      petId: petId ?? this.petId,
      careName: careName ?? this.careName,
      session: session ?? this.session,
    );
  }
}
