// 갈아끼울 수 있는 main screen 위젯
// 하단 내비게이션 바는 고정한 채 main screen 위젯만 교체하는 구조

import 'package:flutter/material.dart';
import '../widgets/molecules/bottom_nav_bar.dart';
// 각 화면들은 나중에 파일로 분리할 예정입니다.
import 'home/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 탭별로 보여줄 화면 리스트
  final List<Widget> _pages = [
    const HomeScreen(), // 홈
    const Center(child: Text("검색 페이지")), // 검색
    const Center(child: Text("일정 페이지")), // 일정
    const Center(child: Text("설정 페이지")), // 설정
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 내비게이션 바 뒤로 배경이 비치게 설정
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
