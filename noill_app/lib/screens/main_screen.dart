// 위젯 트리의 최상위 스크린 (메인 스크린)
// 각 내비게이션의 실제 화면 전환 로직

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/providers/care_provider.dart';
import '../providers/auth_provider.dart';

import '../widgets/molecules/bottom_nav_bar.dart';
import '../widgets/atoms/light_diffusion_background.dart';
import '../widgets/molecules/main_app_bar.dart';

import 'home/home_screen.dart';
import 'schedule/schedule_main_screen.dart';
import 'settings/settings_screen.dart';
import 'package:noill_app/models/call_state.dart';
import 'call/call_screen.dart'; // 화상 통화 화면 가져오기
import 'auth/welcome_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // 1:1 매칭을 위한 페이지 리스트
  List<Widget> get _pages => [
    const HomeScreen(),
    const SizedBox.shrink(), // 🎯 1번 자리는 버튼 동작용이므로 비워둡니다.
    const ScheduleMainScreen(),
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
              // 🎯 [수정] petId 대신 ref를 넘깁니다.
              _showContactSelection(context, ref);
            } else {
              setState(() => _currentIndex = index);
            }
          },
        ),
        // Move the FAB here so it's visible along with the BottomNavigationBar
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // 1. 현재 선택된 어르신 정보를 가져옵니다.
            final selectedPet = ref.read(selectedPetProvider);

            // 2. 선택된 어르신이 없을 경우를 대비한 방어 코드
            if (selectedPet == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("테스트를 위해 어르신을 먼저 선택해주세요.")),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                  // 🎯 [수정] 열거형 타입 확인 (CallStatus)
                  initialState: CallStatus.incoming,
                  // 🎯 [수정] 객체가 아닌 실제 ID(String)와 성함을 전달
                  petId: selectedPet.petId,
                  careName: selectedPet.careName,
                ),
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

  // main_screen.dart 내부 _showContactSelection 수정
  // main_screen.dart 하단 혹은 내부에 있는 함수
  void _showContactSelection(BuildContext context, WidgetRef ref) {
    // 1. 현재 보호자가 관리 중인 어르신 목록을 가져옵니다.
    final careListAsync = ref.read(careListProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => careListAsync.when(
        data: (list) => ListView.builder(
          shrinkWrap: true,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final pet = list[index];
            return ListTile(
              title: Text(pet.careName), // 어르신 성함
              subtitle: Text(pet.petName), // 로봇 이름/별명
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pop(context); // 팝업 닫기

                // 2. 선택된 어르신의 실제 petId와 이름을 전달하며 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallScreen(
                      initialState: CallStatus.calling,
                      petId: pet.petId,
                      careName: pet.careName,
                    ),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text("목록을 불러오지 못했습니다.")),
      ),
    );
  }
}
