// 회원가입 페이지
import 'package:flutter/material.dart';
import 'package:noill_app/screens/main_screen.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/solid_button.dart';
import '../auth/device_pairing_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  // 가입 완료 팝업 함수
  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("환영합니다!", textAlign: TextAlign.center),
        content: const Text(
          "서비스 이용을 위해서는 로봇 등록이 필요합니다.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                SolidButton(
                  text: "로봇 등록하기",
                  onPressed: () {
                    Navigator.pop(dialogContext); // 1. 팝업창 닫기
                    // 2. 기기 연동 화면으로 이동 (build 메서드의 context 사용)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevicePairingScreen(),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // 팝업창 닫기
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text("나중에 등록하기"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("회원가입"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const CustomInputField(label: "이름", hintText: "이름을 입력하세요"),
              const SizedBox(height: 16),
              const CustomInputField(label: "이메일", hintText: "이메일을 입력하세요"),
              const SizedBox(height: 16),
              const CustomInputField(
                label: "비밀번호",
                hintText: "비밀번호를 입력하세요",
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SolidButton(
                text: "가입하기",
                onPressed: () => _showWelcomeDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
