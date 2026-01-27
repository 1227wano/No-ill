// 위젯 트리의 최상위 스크린 (메인 스크린)
// 각 내비게이션의 실제 화면 전환 로직

import 'package:flutter/material.dart';
import '../widgets/molecules/bottom_nav_bar.dart';
import '../widgets/atoms/light_diffusion_background.dart';
import 'home/home_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'accident/accident_history_screen.dart'; // 사고 기록 화면 가져오기
import 'call/video_call_screen.dart'; // 화상 통화 화면 가져오기

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 1:1 매칭을 위한 페이지 리스트
  final List<Widget> _pages = [
    const HomeScreen(),
    const SizedBox.shrink(), // 화상통화 더미
    const ScheduleScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LightDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // --- [중요] 햄버거 메뉴 등록 ---
        drawer: _buildDrawer(context),

        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              // 화상통화 팝업 로직 (기존 유지)
              _showContactSelection(context);
            } else {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }

  // --- 햄버거 메뉴 구성 (Drawer) ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 메뉴 헤더
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF6A85B6),
            ), // NoIllColors.primary
            accountName: Text(
              "User1",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("안녕하세요! 어르신의 안전을 지킵니다."),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF6A85B6)),
            ),
          ),

          // 메뉴 아이템들
          _buildDrawerItem(
            Icons.home_outlined,
            "홈",
            () => Navigator.pop(context),
          ),

          _buildDrawerItem(Icons.history, "사고 기록", () {
            Navigator.pop(context); // 메뉴 닫기
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccidentHistoryScreen(),
              ),
            );
          }),

          _buildDrawerItem(Icons.settings_outlined, "설정", () {
            Navigator.pop(context);
            setState(() => _currentIndex = 3); // 설정 탭으로 이동
          }),

          const Spacer(),
          const Divider(),
          _buildDrawerItem(Icons.logout, "로그아웃", () => Navigator.pop(context)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showContactSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // 기획안의 둥근 모서리 디자인 반영
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물 높이만큼만 차지
          children: [
            // 상단 핸들 바
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "누구에게 연락할까요?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 연락처 리스트: Mary Jane 할머니
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              leading: const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage('assets/images/user_profile.png'),
              ),
              title: const Text(
                "Mary Jane (할머니)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text("최근 통화: 2시간 전"),
              trailing: const Icon(
                Icons.videocam,
                color: Color(0xFF6A85B6),
              ), // NoIllColors.primary
              onTap: () {
                // 1. 먼저 바텀 시트를 닫습니다.
                Navigator.pop(context);

                // 2. 발신(calling) 상태로 화상 통화 전체 화면으로 이동합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const VideoCallScreen(initialState: CallState.calling),
                  ),
                );
              },
            ),

            // 추가 연락처가 있다면 여기에 ListTile을 더 추가할 수 있습니다.
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
