import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import 'elderly_profile_edit_screen.dart'; // 수정 화면
import 'protector_profile_edit_screen.dart'; // 보호자 정보 수정 화면

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LightDiffusionBackground(
      //
      child: Scaffold(
        backgroundColor: Colors.transparent, //
        appBar: AppBar(
          title: const Text("마이페이지"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {}, // 앱 전체 설정 이동
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 보호자(나) 프로필 섹션
              _buildProtectorProfile(context),
              const SizedBox(height: 32),

              // 2. 관리 중인 어르신 섹션
              _buildSectionHeader("관리 중인 어르신", onAdd: () {}),
              const SizedBox(height: 12),
              _buildElderlyCard(
                context,
                name: "Mary Jane",
                relation: "할머니",
                device: "Aibo-Bot v2",
                imagePath: 'assets/images/user_profile.png',
              ),

              // 어르신이 여러 명일 경우 여기에 카드를 추가
              const SizedBox(height: 32),

              // 3. 계정 관리 및 기타 설정
              _buildSectionHeader("계정 관리"),
              const SizedBox(height: 12),
              _buildAccountActions(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌더 메서드들 ---

  // 보호자 프로필 카드
  Widget _buildProtectorProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "보호자님",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "protector@email.com",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProtectorProfileEditScreen(),
                ),
              );
            },
            child: const Text(
              "수정",
              style: TextStyle(color: NoIllColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 헤더
  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: NoIllColors.primary,
            ),
            onPressed: onAdd,
          ),
      ],
    );
  }

  // 어르신 관리 카드
  Widget _buildElderlyCard(
    BuildContext context, {
    required String name,
    required String relation,
    required String device,
    required String imagePath,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          radius: 25,
        ),
        title: Text(
          "$name ($relation)",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("연동 기기: $device", style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // 어르신 정보 상세 수정 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderlyProfileEditScreen(),
            ),
          );
        },
      ),
    );
  }

  // 계정 액션 (로그아웃, 회원탈퇴)
  Widget _buildAccountActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildActionItem(Icons.notifications_none, "알림 설정", () {}),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildActionItem(Icons.exit_to_app, "로그아웃", () {}),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildActionItem(
            Icons.person_remove_outlined,
            "회원 탈퇴",
            () => _showWithdrawalDialog(context),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? NoIllColors.danger : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? NoIllColors.danger : Colors.black87,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // 회원 탈퇴 확인 팝업
  void _showWithdrawalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("정말 떠나시나요?"),
        content: const Text("탈퇴 시 어르신의 모든 활동 기록과 기기 연동 정보가 삭제되며 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {}, // 실제 탈퇴 로직
            child: const Text(
              "탈퇴하기",
              style: TextStyle(color: NoIllColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
