// 사용자(보호자) 프로필 및 기기 관리

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildMenuTile(Icons.person_outline, "내 정보 수정"),
            _buildMenuTile(Icons.smart_toy_outlined, "기기 관리 (Aibo-Bot v2)"),
            _buildMenuTile(Icons.group_outlined, "공동 보호자 초대"),
            _buildMenuTile(Icons.notifications_none, "알림 설정"),
            const Divider(height: 40),
            _buildMenuTile(Icons.help_outline, "고객 센터"),
            _buildMenuTile(Icons.logout, "로그아웃", isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {bool isLast = false}) {
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: isLast
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
