// 보호자 정보 수정

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../widgets/atoms/custom_input_field.dart';

class ProtectorProfileEditScreen extends StatelessWidget {
  const ProtectorProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LightDiffusionBackground(
      // 메인 서비스용 은은한 배경 적용
      child: Scaffold(
        backgroundColor: Colors.transparent, // 배경 위젯을 위해 투명화
        appBar: AppBar(
          title: const Text("내 정보 수정"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. 보호자 프로필 사진 수정
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Color(0xFFE0E0E0),
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: NoIllColors.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. 정보 입력 필드
              const CustomInputField(label: "이름", hintText: "보호자님"),
              const SizedBox(height: 20),
              const CustomInputField(
                label: "이메일",
                hintText: "protector@email.com",
              ),
              const SizedBox(height: 20),
              const CustomInputField(
                label: "휴대폰 번호",
                hintText: "010-0000-0000",
              ),

              const SizedBox(height: 40),

              // 3. 변경 사항 저장 버튼
              SolidButton(
                text: "변경 사항 저장",
                onPressed: () {
                  // 수정 로직 실행 후 이전 화면으로
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 16),

              // 4. 회원 탈퇴 버튼 (하단에 작게 배치)
              TextButton(
                onPressed: () => _showWithdrawalDialog(context),
                child: const Text(
                  "회원 탈퇴하기",
                  style: TextStyle(
                    color: NoIllColors.danger,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 회원 탈퇴 확인 팝업
  void _showWithdrawalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("정말 탈퇴하시겠습니까?"),
        content: const Text("회원 탈퇴 시 모든 보호 데이터와 기기 연동 정보가 즉시 삭제되며 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              // 실제 탈퇴 로직 및 초기 화면(Login)으로 이동
            },
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
