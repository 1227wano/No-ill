import 'package:flutter/material.dart';
import 'package:noill_app/screens/main_screen.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/solid_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.favorite, size: 40, color: Color(0xFF6DB3F2)),
                const SizedBox(height: 16),
                const Text(
                  "No-ill",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 60),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "보호자님, 반갑습니다!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 32),
                const CustomInputField(label: "이메일/ID", hintText: "이메일을 입력하세요"),
                const SizedBox(height: 16),
                const CustomInputField(
                  label: "비밀번호",
                  hintText: "비밀번호를 입력하세요",
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SolidButton(
                  text: "로그인",
                  onPressed: () {
                    // 모든 이전 화면 제거하고 main screen으로 이동
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("처음이신가요? "),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                      child: const Text(
                        "계정 만들기",
                        style: TextStyle(
                          color: Color(0xFF6DB3F2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
