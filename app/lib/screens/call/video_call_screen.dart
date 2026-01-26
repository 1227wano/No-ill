//  화상통화
import 'package:flutter/material.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 어르신 화면 (전체 배경)
          Positioned.fill(
            child: Image.asset(
              'assets/images/elderly_face.png', // 어르신 얼굴 이미지 mock
              fit: BoxFit.cover,
            ),
          ),

          // 2. 보호자 화면 (우측 상단 PIP)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/images/user_profile.png',
                  ), // 보호자 얼굴 mock
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 3. 상단 이름 및 상태 표시
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Mary Jane",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "05:24",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // 4. 하단 제어 버튼
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallAction(Icons.mic_off, Colors.white.withOpacity(0.2)),
                const SizedBox(width: 20),
                _buildCallAction(Icons.call_end, Colors.red, isEnd: true),
                const SizedBox(width: 20),
                _buildCallAction(
                  Icons.videocam_off,
                  Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction(IconData icon, Color bgColor, {bool isEnd = false}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
