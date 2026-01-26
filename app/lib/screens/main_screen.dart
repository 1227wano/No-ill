// 갈아끼울 수 있는 main screen 위젯
// 하단 내비게이션 바는 고정한 채 main screen 위젯만 교체하는 구조
// 하단 내비게이션 바 기능 활성화도 이 파일에서 관리

import 'package:flutter/material.dart';
import '../widgets/molecules/bottom_nav_bar.dart';
// 각 화면들은 나중에 파일로 분리할 예정입니다.
import 'home/home_screen.dart';
import 'call/video_call_screen.dart'; // 수정된 화상통화 화면
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 인덱스에 매칭되는 실제 화면들 (인덱스 관리)
  final List<Widget> _pages = [
    const HomeScreen(),
    const VideoCallScreen(), // 화상통화 탭
    const ScheduleScreen(), // 일정 탭
    const SettingsScreen(), // 설정 탭
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 내비게이션 바 뒤로 배경이 비치게 설정
      // indexedStack을 사용하면 탭 전환 시 기존 화면 상태가 유지되어 더 매끄러움
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // 사용자가 클릭한 인덱스로 상태 업데이트
          });
        },
      ),
    );
  }
}
