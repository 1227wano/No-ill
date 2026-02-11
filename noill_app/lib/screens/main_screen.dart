// 위젯 트리의 최상위 스크린 (메인 스크린)
// 각 내비게이션의 실제 화면 전환 로직

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_provider.dart';

import '../widgets/molecules/bottom_nav_bar.dart';
import '../widgets/atoms/light_diffusion_background.dart';
import '../widgets/molecules/main_app_bar.dart';

import 'home/home_screen.dart';
import 'schedule/schedule_main_screen.dart';
import 'settings/settings_screen.dart';
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

    return SafeArea(
      child: LightDiffusionBackground(
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
        ),
      ),
    );
  }

  // main_screen.dart 하단 혹은 내부에 있는 함수
  void _showContactSelection(BuildContext context, WidgetRef ref) {
    // 1. 현재 보호자가 관리 중인 어르신 목록을 가져옵니다.
    final careListAsync = ref.read(careListProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // ✅ RobotSection과 동일한 상단 30r 라운드 적용
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.w), // ✅ 동일한 24 패딩
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ 콘텐츠 크기만큼만 차지
          children: [
            // ✅ 타이틀 스타일 통일
            Text(
              "화상통화 대상 선택",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),

            careListAsync.when(
              data: (list) => ListView.builder(
                shrinkWrap: true, // ✅ Column 내부에서 필수
                physics: const NeverScrollableScrollPhysics(), // 내부 스크롤 방지
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final pet = list[index];
                  // ✅ RobotSection의 _buildModeItem 스타일로 구현
                  return ListTile(
                    contentPadding: EdgeInsets.zero, // 기본 패딩 제거
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: NoIllColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: NoIllColors.primary,
                      ),
                    ),
                    title: Text(
                      pet.careName, // 어르신 성함
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    subtitle: Text(
                      "${pet.petName} (로봇) 연결하기", // 로봇 이름/별명 포함 문구
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoCallScreen(
                            petId: pet.petId,
                            careName: pet.careName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: NoIllColors.primary),
              ),
              error: (err, _) => Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  "목록을 불러오지 못했습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(height: 10.h), // 하단 여백 추가
          ],
        ),
      ),
    );
  }
}
