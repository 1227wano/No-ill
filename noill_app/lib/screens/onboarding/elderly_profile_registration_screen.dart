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

              // 프로필 사진 등록
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const CustomInputField(label: "어르신 성함", hintText: "예: 김복순 할머니"),
              const SizedBox(height: 20),
              const CustomInputField(label: "연령", hintText: "예: 82세"),
              const SizedBox(height: 20),
              const CustomInputField(label: "관계", hintText: "예: 모친, 조모"),

              const SizedBox(height: 60),
              SolidButton(
                text: "등록 완료하고 시작하기",
                onPressed: () {
                  // 온보딩 스택을 모두 제거하고 메인 화면으로 이동합니다.
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false, // 이전 경로들을 모두 제거하여 '뒤로가기'를 방지합니다.
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
