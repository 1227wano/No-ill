import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/providers/call_privoder.dart';
import 'package:openvidu_flutter/widgets/participant_widget.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String petId;
  final String careName;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.petId,
    required this.careName,
    this.isIncoming = false,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isIncoming) {
        // 수신: 자동으로 전화 받기 (디스플레이 디바이스)
        ref.read(callProvider.notifier).acceptIncomingCall();
      } else {
        // 발신: 통화 시작
        ref.read(callProvider.notifier).startCall(widget.petId, widget.careName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final session = callState.session;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 배경: 원격 참가자 영상 또는 대기 화면
          _buildBackground(callState),

          // 2. 내 화면 (PIP) - 로컬 카메라가 활성화된 경우
          if (session?.localParticipant != null)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120.w,
                height: 160.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: session!.localParticipant!.isVideoActive
                      ? RTCVideoView(
                          session.localParticipant!.renderer,
                          mirror: session.localParticipant!.isFrontCameraActive,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white54, size: 32),
                          ),
                        ),
                ),
              ),
            ),

          // 3. 중앙 UI (연결 전 상태 표시)
          if (callState.status != CallStatus.connected) _buildCenterUI(callState),

          // 4. 하단 컨트롤 바
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _buildControlBar(callState),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(CallState callState) {
    final session = callState.session;
    final remoteParticipants = session?.remoteParticipants.entries.toList() ?? [];

    // 연결되고 원격 참가자가 있으면 영상 표시
    if (callState.status == CallStatus.connected && remoteParticipants.isNotEmpty) {
      final remote = remoteParticipants.first.value;
      return Positioned.fill(
        child: ParticipantWidget(participant: remote),
      );
    }

    return Positioned.fill(
      child: Container(color: const Color(0xFF2C3E50)),
    );
  }

  Widget _buildCenterUI(CallState callState) {
    String statusText;
    switch (callState.status) {
      case CallStatus.calling:
        statusText = '연결 중...';
        break;
      case CallStatus.incoming:
        statusText = '전화 수신 중...';
        break;
      case CallStatus.ended:
        statusText = '통화 종료';
        break;
      default:
        statusText = '';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            widget.careName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(CallState callState) {
    final session = callState.session;
    final isAudioActive = session?.localParticipant?.isAudioActive ?? true;
    final isVideoActive = session?.localParticipant?.isVideoActive ?? true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 마이크 토글
        _buildActionBtn(
          isAudioActive ? Icons.mic : Icons.mic_off,
          Colors.white.withOpacity(isAudioActive ? 0.2 : 0.5),
          onTap: () => ref.read(callProvider.notifier).toggleAudio(),
        ),
        const SizedBox(width: 30),
        // 전화 끊기
        _buildActionBtn(
          Icons.call_end,
          Colors.red,
          onTap: () {
            ref.read(callProvider.notifier).endCall();
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 30),
        // 카메라 토글
        _buildActionBtn(
          isVideoActive ? Icons.videocam : Icons.videocam_off,
          Colors.white.withOpacity(isVideoActive ? 0.2 : 0.5),
          onTap: () => ref.read(callProvider.notifier).toggleVideo(),
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 32.sp),
      ),
    );
  }
}
