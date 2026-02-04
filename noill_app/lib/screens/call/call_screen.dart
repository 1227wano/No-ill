import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/providers/call_privoder.dart';

class VideoCallScreen extends StatefulWidget {
  final CallStatus initialState;
  final String petId;
  final String careName;

  const VideoCallScreen({
    super.key,
    required this.initialState,
    required this.petId,
    required this.careName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late CallStatus _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;

    // 발신 중(calling)일 때만 자동으로 렌더러 초기화 및 타이머 작동
    if (_currentState == CallStatus.calling) {
      // 🎯 화면이 그려진 후 바로 카메라 권한 요청 및 렌더러 초기화
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ProviderScope.containerOf(
          context,
        ).read(callProvider.notifier).initRenderers();
      });
      _startAutoConnectTimer();
    }
  }

  void _startAutoConnectTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentState == CallStatus.calling) {
        setState(() => _currentState = CallStatus.connected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // 🎯 여기서 callProvider를 구독합니다.
        final callState = ref.watch(callProvider);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 1. 배경 (연결 전에는 어두운 배경, 연결 후에는 어르신 영상)
              _buildBackground(callState),

              // 2. 내 화면 (오른쪽 상단 PIP) - 카메라 권한 허용 및 스트림 획득 시 노출
              if (callState.localRenderer != null &&
                  callState.localRenderer!.srcObject != null)
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
                      child: RTCVideoView(
                        callState.localRenderer!,
                        mirror: true, // 내 화면은 거울 모드
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // 3. 중앙 텍스트 및 프로필 UI
              _buildCenterUI(),

              // 4. 하단 컨트롤 바
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: _buildControlBar(ref), // ref를 넘겨서 notifier 호출 가능하게 함
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI 구성 요소 메서드들 ---

  Widget _buildBackground(dynamic callState) {
    // 🎯 연결된 상태이고 원격 스트림이 있다면 영상을 보여줍니다.
    if (_currentState == CallStatus.connected &&
        callState.remoteRenderer != null) {
      return Positioned.fill(
        child: RTCVideoView(
          callState.remoteRenderer!,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      );
    }

    // 연결 전에는 기존 배경색과 이미지를 보여줍니다.
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF2C3E50),
        child: _currentState == CallStatus.connected
            ? Image.asset(
                'assets/images/elderly_face.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              )
            : null,
      ),
    );
  }

  Widget _buildCenterUI() {
    if (_currentState == CallStatus.idle) return _buildIdleUI();
    if (_currentState == CallStatus.calling) return _buildCallingUI();
    if (_currentState == CallStatus.incoming) return _buildIncomingUI();
    return const SizedBox.shrink();
  }

  Widget _buildCallingUI() {
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
          const Text(
            "연결 중...",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withOpacity(0.5),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
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
          const Text(
            "화상통화 요청 중",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "화상통화",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionBtn(
                Icons.call,
                Colors.green,
                "발신",
                onTap: () {
                  setState(() => _currentState = CallStatus.calling);
                  _startAutoConnectTimer();
                },
              ),
              const SizedBox(width: 40),
              _buildActionBtn(
                Icons.call_received,
                Colors.blue,
                "수신",
                onTap: () {
                  setState(() => _currentState = CallStatus.incoming);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(WidgetRef ref) {
    if (_currentState == CallStatus.idle) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionBtn(Icons.mic_off, Colors.white.withOpacity(0.2), ""),
        const SizedBox(width: 30),
        _buildActionBtn(
          Icons.call_end,
          Colors.red,
          "",
          onTap: () {
            // 🎯 종료 시 렌더러 리소스 해제 호출
            ref.read(callProvider.notifier).endCall();
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 30),
        _buildActionBtn(Icons.volume_up, Colors.white.withOpacity(0.2), ""),
      ],
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    Color color,
    String label, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32.sp),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ],
    );
  }
}
