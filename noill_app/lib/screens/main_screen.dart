// 위젯 트리의 최상위 스크린 (메인 스크린)
// 각 내비게이션의 실제 화면 전환 로직

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

import '../widgets/molecules/bottom_nav_bar.dart';
import '../widgets/atoms/light_diffusion_background.dart';
import '../widgets/molecules/main_app_bar.dart';

import 'home/home_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'call/video_call_screen.dart'; // 화상 통화 화면 가져오기
import 'auth/welcome_screen.dart'; // Splash 화면으로 로그아웃 후 이동

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
    // authProvider 의 상태 실시간 감시 -> 로그아웃 시 화면 재빌드
    ref.listen(authProvider, (previous, next) {
      // 이전에는 로그인, 현재 로그아웃 상태로 변한다면
      final previousStatus = previous?.status; // 이전 데이터
      final nextStatus = next.status;

      if (previousStatus == AuthStatus.authenticated &&
          nextStatus == AuthStatus.unauthenticated) {
        //  1. 하단에 검은색 스낵바 띄우기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("세션이 만료되었습니다. 다시 로그인해주세요."),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 3),
          ),
        );
        // 2. 로그인 화면 (splash)으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false, // 뒤로가기 방지를 위해 모든 경로 삭제
        );
      }
    });

    return LightDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        // 메인 상단
        appBar: const MainAppBar(),
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
        // Move the FAB here so it's visible along with the BottomNavigationBar
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
        ),
      ),
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
