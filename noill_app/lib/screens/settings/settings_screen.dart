// 사용자(보호자) 프로필 및 기기 관리

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: NoIllColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          children: [
            const Text(
              "설정",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // 프로필 섹션
            const Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage('assets/images/user_profile.png'),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Justin Mason",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("주보호자", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            // 설정 메뉴 리스트
            _buildMenuTile(Icons.person_outline, "내 정보 수정", onTap: () {}),
            _buildMenuTile(
              Icons.smart_toy_outlined,
              "기기 관리 (Aibo-Bot v2)",
              onTap: () {},
            ),
            _buildMenuTile(Icons.group_outlined, "공동 보호자 초대", onTap: () {}),
            _buildMenuTile(Icons.notifications_none, "알림 설정", onTap: () {}),
            const Divider(height: 40),
            _buildMenuTile(Icons.help_outline, "고객 센터", onTap: () {}),
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
