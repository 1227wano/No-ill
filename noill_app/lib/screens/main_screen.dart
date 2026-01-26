// 위젯 트리의 최상위 스크린 (메인 스크린)

import 'package:flutter/material.dart';
import '../widgets/molecules/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'accident/accident_history_screen.dart'; // 사고 기록 화면 가져오기

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
    return Scaffold(
      // --- [중요] 햄버거 메뉴 등록 ---
      drawer: _buildDrawer(context),

      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            // 화상통화 팝업 로직 (기존 유지)
          } else {
            setState(() => _currentIndex = index);
          }
        },
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
}
