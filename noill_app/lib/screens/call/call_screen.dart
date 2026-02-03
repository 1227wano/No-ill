import 'package:flutter/material.dart';

enum CallState { none, calling, incoming, connected } // 통화 상태 정의

class VideoCallScreen extends StatefulWidget {
  final CallState initialState;
  const VideoCallScreen({super.key, this.initialState = CallState.none});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late CallState _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;

    /// [수정] 발신 중(calling)일 때만 자동으로 연결되게 하고,
    // 수신 중(incoming)일 때는 사용자가 누를 때까지 기다립니다.
    if (_currentState == CallState.calling) {
      Future.delayed(const Duration(seconds: 3), () {
        // 시간을 3초로 늘려 확인하기 편하게 변경
        if (mounted) setState(() => _currentState = CallState.connected);
      });
    }
  }

  // ... 배경화면 이미지 에러 방지 처리
  Widget _buildBackground() {
    if (_currentState == CallState.connected) {
      return Positioned.fill(
        child: Image.asset(
          'assets/images/elderly_face.png',
          fit: BoxFit.cover,
          // 이미지가 없을 때 에러 대신 회색 배경을 보여줌
          errorBuilder: (context, error, stackTrace) =>
              Container(color: Colors.grey[900]),
        ),
      );
    }
    return Positioned.fill(child: Container(color: const Color(0xFF2C3E50)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 배경 (연결 전에는 프로필, 연결 후에는 카메라 화면)
          _buildBackground(),

          // 2. 중앙 정보 (발신 중일 때 노출)
          if (_currentState == CallState.calling)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(
                      'assets/images/user_profile.png',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Mary Jane",
                    style: TextStyle(
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
            ),

          // 2.5. 초기 상태일 때 발신/수신 버튼
          if (_currentState == CallState.none)
            Center(
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
                        onTap: () =>
                            setState(() => _currentState = CallState.calling),
                      ),
                      const SizedBox(width: 40),
                      _buildActionBtn(
                        Icons.call_received,
                        Colors.blue,
                        "수신",
                        onTap: () =>
                            setState(() => _currentState = CallState.incoming),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 2.6. 수신 중일 때 중앙 정보
          if (_currentState == CallState.incoming)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 수신 중일 때 프로필 테두리에 강조 효과
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent.withOpacity(0.5),
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(
                        'assets/images/user_profile.png',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Mary Jane",
                    style: TextStyle(
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
            ),

          // 3. 하단 컨트롤 바 (상태별 버튼 구성 변경)
          Positioned(bottom: 60, left: 0, right: 0, child: _buildControlBar()),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    if (_currentState == CallState.none) {
      return const SizedBox.shrink(); // 초기 상태에서는 컨트롤 바 없음
    }
    if (_currentState == CallState.incoming) {
      // 수신 중: 거절(Red) / 수락(Green) 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionBtn(
            Icons.call_end,
            Colors.red,
            "거절",
            onTap: () => Navigator.pop(context), // 통화 거절 시 뒤로 가기
          ),
          _buildActionBtn(
            Icons.videocam,
            Colors.green,
            "수락",
            onTap: () => setState(() => _currentState = CallState.connected),
          ),
        ],
      );
    } else {
      // 통화 중/발신 중: 음소거, 종료, 스피커
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionBtn(Icons.mic_off, Colors.white.withOpacity(0.2), ""),
          const SizedBox(width: 30),
          _buildActionBtn(
            Icons.call_end,
            Colors.red,
            "",
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 30),
          _buildActionBtn(Icons.volume_up, Colors.white.withOpacity(0.2), ""),
        ],
      );
    }
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
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
