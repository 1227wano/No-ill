// lib/providers/call_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvidu_flutter/utils/session.dart';
import 'package:openvidu_flutter/participant/local_participant.dart';
import 'package:openvidu_flutter/utils/custom_websocket.dart';
import '../models/call_state.dart';
import '../services/openvidu_service.dart';
import '../core/network/dio_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';

// ═══════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════

final openViduServiceProvider = Provider<OpenViduService>((ref) {
  final dio = ref.read(dioProvider);
  return OpenViduService(dio);
});

final callProvider = NotifierProvider<CallNotifier, CallState>(() {
  return CallNotifier();
});

// ═══════════════════════════════════════════════════════════════════════
// CallNotifier
// ═══════════════════════════════════════════════════════════════════════

class CallNotifier extends Notifier<CallState> {
  final _logger = AppLogger('CallNotifier');

  OpenViduService? _serviceInstance;

  OpenViduService get _service {
    _serviceInstance ??= ref.read(openViduServiceProvider);
    return _serviceInstance!;
  }

  @override
  CallState build() {
    return CallState();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Public Methods - 통화 제어
  // ═══════════════════════════════════════════════════════════════════════

  /// 발신: 보호자가 어르신에게 전화를 걸 때
  Future<void> startCall(String petId, String careName) async {
    try {
      _logger.info('발신 통화 시작: $petId / $careName');

      state = state.copyWith(
        status: CallStatus.calling,
        petId: petId,
        careName: careName,
      );

      // Step 1: 세션 생성
      final sessionResult = await _service.createSession();
      final sessionId = sessionResult.fold(
        onSuccess: (id) {
          _logger.info('세션 생성 성공: $id');
          return id;
        },
        onFailure: (exception) {
          _logger.error('세션 생성 실패: ${exception.message}');
          _endCallWithError('세션 생성에 실패했습니다');
          throw exception;
        },
      );

      // Step 2: 토큰 발급
      final tokenResult = await _service.getConnectionToken(sessionId);
      final token = tokenResult.fold(
        onSuccess: (token) {
          _logger.info('토큰 발급 성공');
          return token;
        },
        onFailure: (exception) {
          _logger.error('토큰 발급 실패: ${exception.message}');
          _endCallWithError('연결 토큰 발급에 실패했습니다');
          throw exception;
        },
      );

      // 상태 업데이트
      state = state.copyWith(sessionId: sessionId, token: token);

      // Step 3: 상대방 호출 (실패해도 계속 진행)
      final notifyResult = await _service.notifyCall(petId, sessionId);
      notifyResult.fold(
        onSuccess: (_) => _logger.info('상대방 호출 성공'),
        onFailure: (exception) =>
            _logger.warning('상대방 호출 실패 (무시): ${exception.message}'),
      );

      // Step 4: OpenVidu 연결
      _logger.info('OpenVidu 연결 시작');
      await _connectToOpenVidu(sessionId, token);
    } catch (e, stackTrace) {
      _logger.error('발신 통화 시작 실패', e, stackTrace);
      _endCallWithError('통화 연결에 실패했습니다');
    }
  }

  /// 수신: 어르신이 보호자의 전화를 받을 때
  Future<void> acceptIncomingCall() async {
    final sessionId = state.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      _logger.error('수신 수락 실패: sessionId 없음');
      _endCallWithError('세션 정보가 없습니다');
      return;
    }

    try {
      _logger.info('수신 전화 수락: $sessionId');

      // Step 1: 토큰 발급
      final tokenResult = await _service.getConnectionToken(sessionId);
      final token = tokenResult.fold(
        onSuccess: (token) {
          _logger.info('토큰 발급 성공');
          return token;
        },
        onFailure: (exception) {
          _logger.error('토큰 발급 실패: ${exception.message}');
          _endCallWithError('연결 토큰 발급에 실패했습니다');
          throw exception;
        },
      );

      // 상태 업데이트
      state = state.copyWith(token: token);

      // Step 2: OpenVidu 연결
      _logger.info('OpenVidu 연결 시작');
      await _connectToOpenVidu(sessionId, token);
    } catch (e, stackTrace) {
      _logger.error('수신 전화 수락 실패', e, stackTrace);
      _endCallWithError('통화 연결에 실패했습니다');
    }
  }

  /// 수신 전화 정보 설정
  void setIncomingCall(String sessionId, String petId, String careName) {
    _logger.info('수신 전화 설정: $sessionId / $petId / $careName');

    state = state.copyWith(
      status: CallStatus.incoming,
      sessionId: sessionId,
      petId: petId,
      careName: careName,
    );
  }

  /// 통화 종료
  void endCall() {
    _logger.info('통화 종료 시도');

    try {
      // OpenVidu 세션 종료
      state.session?.leaveSession();
      _logger.info('OpenVidu 세션 종료 완료');
    } catch (e) {
      _logger.warning('세션 종료 중 오류 (무시): $e');
    }

    // 상태 초기화
    state = CallState();
    _logger.info('통화 상태 초기화 완료');
  }

  /// 마이크 토글
  void toggleAudio() {
    _logger.debug('마이크 토글');
    state.session?.localToggleAudio();
    _refreshState();
  }

  /// 카메라 토글
  void toggleVideo() {
    _logger.debug('카메라 토글');
    state.session?.localToggleVideo();
    _refreshState();
  }

  /// 카메라 전환 (전면/후면)
  void switchCamera() {
    _logger.debug('카메라 전환');
    state.session?.localParticipant?.switchCamera();
    _refreshState();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private Methods - OpenVidu 연결
  // ═══════════════════════════════════════════════════════════════════════

  /// OpenVidu 서버에 WebRTC 연결 수립
  Future<void> _connectToOpenVidu(String sessionId, String token) async {
    try {
      _logger.info('OpenVidu 연결 시작: $sessionId');

      // 1. Session 생성
      final session = Session(sessionId, token);
      _setupSessionEventHandlers(session);

      // 2. 로컬 참가자 생성 및 카메라 초기화
      final localParticipant = LocalParticipant('user', session);
      await _initializeLocalCamera(localParticipant);

      // 3. WebSocket 연결
      final webSocket = _createWebSocket(session);
      session.setWebSocket(webSocket);

      // 4. 연결 중 상태
      state = state.copyWith(session: session, status: CallStatus.connecting);

      // 5. WebSocket 연결 시작
      webSocket.connect();
      _logger.info('WebSocket 연결 요청 완료');

      // 6. 연결 완료 상태
      state = state.copyWith(session: session, status: CallStatus.connected);

      _logger.info('OpenVidu 연결 완료');
    } catch (e, stackTrace) {
      _logger.error('OpenVidu 연결 실패', e, stackTrace);
      _endCallWithError('영상 통화 연결에 실패했습니다');
    }
  }

  /// Session 이벤트 핸들러 설정
  void _setupSessionEventHandlers(Session session) {
    // 원격 스트림 수신
    session.onNotifySetRemoteMediaStream = (String connectionId) {
      _logger.info('원격 스트림 수신: $connectionId');
      _refreshState();
    };

    // 원격 참가자 입장
    session.onAddRemoteParticipant = (String connectionId) {
      _logger.info('원격 참가자 입장: $connectionId');
      _refreshState();
    };

    // 원격 참가자 퇴장
    session.onRemoveRemoteParticipant = (String connectionId) {
      _logger.info('원격 참가자 퇴장: $connectionId');
      _refreshState();
    };

    // 메시지 스트림 구독
    session.messageStream.listen(
      (_) {
        _logger.debug('메시지 수신');
        _refreshState();
      },
      onError: (error) {
        _logger.error('메시지 스트림 에러: $error');
      },
    );
  }

  /// 로컬 카메라 초기화
  Future<void> _initializeLocalCamera(LocalParticipant localParticipant) async {
    try {
      _logger.info('로컬 카메라 초기화 시작');

      await localParticipant.renderer.initialize();
      await localParticipant.startLocalCamera();

      _logger.info('로컬 카메라 초기화 완료');
    } catch (e, stackTrace) {
      _logger.error('카메라 초기화 실패', e, stackTrace);
      // 카메라 실패는 치명적이지 않으므로 계속 진행
    }
  }

  /// WebSocket 생성 및 설정
  CustomWebSocket _createWebSocket(Session session) {
    final webSocket = CustomWebSocket(
      session,
      customClient: HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              _logger.debug('SSL 인증서 검증 우회 (개발 모드)');
              return true;
            },
    );

    // WebSocket 에러 핸들러
    webSocket.onErrorEvent = (error) {
      _logger.error('WebSocket 에러: $error');
      _endCallWithError('연결이 끊어졌습니다');
    };

    return webSocket;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private Methods - 유틸리티
  // ═══════════════════════════════════════════════════════════════════════

  /// 상태 새로고침 (UI 업데이트 트리거)
  void _refreshState() {
    state = state.copyWith();
  }

  /// 에러와 함께 통화 종료
  void _endCallWithError(String errorMessage) {
    _logger.error('통화 종료: $errorMessage');

    state = state.copyWith(
      status: CallStatus.ended,
      errorMessage: errorMessage,
    );
  }
}
