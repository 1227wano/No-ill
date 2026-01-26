// 홈화면
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import 'package:noill_app/screens/call/video_call_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoIllColors.background, // Milky Ivory 배경
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // 내비바 공간 확보
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(), // 1. 상단 프로필 및 알림
              const SizedBox(height: 24),
              _buildStatusCard(), // 2. 안심 상태 카드
              const SizedBox(height: 32),
              _buildRobotSection(), // 3. 로봇 상태 및 제어
              const SizedBox(height: 32),
              _buildAgendaSection(), // 4. 오늘의 일정 리스트
            ],
          ),
        ),
      ),

      // TEST 용 FAB버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const VideoCallScreen(initialState: CallState.incoming),
            ),
          );
        },
        label: const Text("수신 테스트"),
        icon: const Icon(Icons.call_received),
        backgroundColor: Colors.blueAccent,
      ), // TEST
    );
  }

  // --- 위젯 구성 요소들 ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/user_profile.png'),
            ), //
            const SizedBox(width: 12),
            const Text(
              "Mary Jane",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ), //
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]), //
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: const Icon(
            Icons.notifications_none,
            size: 24,
            color: NoIllColors.primary,
          ), //
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/room_view.png',
            height: 140,
            fit: BoxFit.cover,
          ), // 방 이미지
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: NoIllColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "STATUS: SAFE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NoIllColors.primary,
                  letterSpacing: 1.2,
                ),
              ), //
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Everything looks good",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ), //
          const SizedBox(height: 4),
          const Text(
            "Last updated: 2 minutes ago",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ), //
        ],
      ),
    );
  }

  Widget _buildRobotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Companion: Aibo-Bot v2",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ), //
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NoIllColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "ACTIVE",
                style: TextStyle(
                  fontSize: 10,
                  color: NoIllColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ), //
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 로봇 제어 바
        Row(
          children: [
            _buildActionBtn(Icons.videocam, "View Camera"),
            const SizedBox(width: 12),
            _buildActionBtn(Icons.phone, "Call Pet"),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: NoIllColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today’s Agenda",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ), //
        const SizedBox(height: 16),
        _buildAgendaItem("Evening Check-in", "6:00 PM", true), // High Priority
        _buildAgendaItem(
          "Morning Medication",
          "8:30 AM",
          false,
          isDone: true,
        ), //
      ],
    );
  }

  Widget _buildAgendaItem(
    String title,
    String time,
    bool isUrgent, {
    bool isDone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUrgent
                  ? NoIllColors.danger.withOpacity(0.1)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber : Icons.medication,
              color: isUrgent ? NoIllColors.danger : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                isDone ? "Completed at $time" : time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
