import 'package:flutter/material.dart';
import '../widgets/molecules/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'call/video_call_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';

// 여러 위젯을 상태에 따라 전환하는 메인 스크린
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 인덱스를 하단 바 아이콘 순서와 1:1로 매칭합니다.
  final List<Widget> _pages = [
    const HomeScreen(), // Index 0
    const SizedBox.shrink(), // Index 1: 화상 통화 (내비바 공간 확보용 더미)
    const ScheduleScreen(), // Index 2
    const SettingsScreen(), // Index 3
  ];

  // 1. 연락처 선택 다이얼로그 (함수를 build 밖으로 뺐습니다)
  void _showContactSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "누구에게 연락할까요?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/user_profile.png'),
              ),
              title: const Text("Mary Jane (할머니)"),
              subtitle: const Text("최근 통화: 2시간 전"),
              onTap: () {
                Navigator.pop(context); // 팝업 닫기

                // 2. 대상을 선택하면 '발신' 상태로 통화 화면 진입 (Full Screen)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const VideoCallScreen(initialState: CallState.calling),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // 필요시 여기에 더 많은 연락처 추가 가능
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 내비게이션 바 배경 투명화 지원
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            // 화상 통화 아이콘 클릭 시 팝업 노출
            _showContactSelection(context);
          } else {
            // 다른 탭 클릭 시 화면 전환
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
