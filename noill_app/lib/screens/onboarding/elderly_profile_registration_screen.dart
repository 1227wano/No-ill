// 어르신 환경 설정 화면

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../main_screen.dart'; // 메인 스크린 임포트

class ElderlyProfileRegistrationScreen extends StatelessWidget {
  const ElderlyProfileRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoIllColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "이제 노일(No-ill)이\n누구를 지켜드릴까요?", // 감성적인 UX 라이팅
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "보호하실 분의 정보를 알려주시면 세심한 케어가 시작됩니다.",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 40),

              // 1. 프로필 사진 등록 섹션
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        size: 50,
                        color: Colors.grey[300],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
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
              const SizedBox(height: 48),

              // 2. 상세 정보 입력 섹션
              const CustomInputField(label: "성함", hintText: "어르신의 성함을 입력해주세요."),
              const SizedBox(height: 24),

              const CustomInputField(
                label: "생년월일",
                hintText: "예: 1945. 01. 01",
              ),
              const SizedBox(height: 24),

              const CustomInputField(
                label: "거주 주소",
                hintText: "어르신이 계신 상세 주소를 입력해주세요.",
              ),
              const SizedBox(height: 24),

              const CustomInputField(
                label: "비상 연락처",
                hintText: "010-0000-0000",
              ),

              const SizedBox(height: 60),

              // 3. 등록 완료 버튼
              SolidButton(
                text: "등록 완료하고 시작하기",
                onPressed: () {
                  // 온보딩 완료 후 메인 화면으로 이동 (뒤로가기 방지)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
