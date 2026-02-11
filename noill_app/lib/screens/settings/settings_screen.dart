// 사용자(보호자) 프로필 및 기기 관리

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';

import '../auth/welcome_screen.dart';
import '../onboarding/device_pairing_screen.dart';
import '../mypage/mypage_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 유저 네임
    final authState = ref.watch(authProvider);
    final user = authState.userData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w), // 홈 화면과 동일한 패딩
          children: [
            SizedBox(height: AppLayout.topSectionGap),
            Text(
              "설정",
              style: TextStyle(
                fontSize: 24.sp, // ScreenUtil 적용
                fontWeight: FontWeight.w800, // 더 두껍게 (홈 화면 타이틀과 통일)
                color: Colors.black,
                letterSpacing: -0.5, // 자간을 살짝 좁혀 정돈된 느낌 부여
              ),
            ),
            SizedBox(height: 16.h), // 홈 화면과 동일한 높이 부여
            SizedBox(width: 20.h), // 홈 화면과 동일한 높이 부여
            // 프로필 섹션
            // 프로필 섹션을 Container로 감싸서 '카드' 느낌 주기
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35.r,
                    backgroundColor: NoIllColors.primary.withOpacity(
                      0.1,
                    ), // 너무 진하지 않게 조정
                    child: Icon(
                      Icons.person_rounded,
                      size: 40.sp,
                      color: NoIllColors.primary, // 아이콘을 브랜드 컬러로
                    ),
                  ),
                  SizedBox(height: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userName ?? "사용자",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "주보호자",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 설정 메뉴 리스트
            _buildMenuTile(
              Icons.person_outline,
              "마이페이지",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPageScreen()),
                );
              },
            ),

            // 3. 기기 관리
            _buildMenuTile(
              Icons.smart_toy_outlined,
              "노일이 등록하기",
              onTap: () {
                // 💡 [핵심] 기기 연동 화면으로 이동합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DevicePairingScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 40),

            // 로그아웃
            _buildMenuTile(
              Icons.logout,
              "로그아웃",
              isLast: true,
              onTap: () => _handleLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // --- [로직] 로그아웃 실행 함수 ---
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // 1. 확인 다이얼로그 띄우기 (실수 방지)
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("정말로 로그아웃 하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("확인", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 2. AuthProvider를 통해 로그아웃 실행 (서버 통신 및 상태 초기화)
      await ref.read(authProvider.notifier).logout();

      // 3. 시작 화면(Splash)으로 이동 (앱 초기 상태로 되돌리기)
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: NoIllColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: title == "로그아웃" ? Colors.redAccent : Colors.black,
        ),
      ),
      trailing: isLast
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
