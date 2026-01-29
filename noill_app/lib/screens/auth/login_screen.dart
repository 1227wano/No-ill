// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
// import 'package:noill_app/screens/main_screen.dart'; // 기존 방식 대신 라우터 권장
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/solid_button.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 1. 입력값을 제어할 컨트롤러 (ID, Password)
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. 현재 인증 상태를 지켜봅니다 (로딩 상태 등을 알기 위해)
    final authState = ref.watch(authProvider);

    return DualDiffusionBackground(
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

                // 3. 컨트롤러를 인풋 필드에 연결합니다
                CustomInputField(
                  label: "아이디",
                  hintText: "ID를 입력하세요",
                  controller: _idController,
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  label: "비밀번호",
                  hintText: "비밀번호를 입력하세요",
                  obscureText: true,
                  controller: _pwController,
                ),
                const SizedBox(height: 32),

                // 4. 로그인 버튼에 실제 서버 연동 로직을 연결합니다
                SolidButton(
                  text: authState.isLoading ? "로그인 중..." : "로그인",
                  onPressed: authState.isLoading ? null : () => _handleLogin(),
                ),
                const SizedBox(height: 16),
                // 비밀번호 찾기 버튼
                TextButton(
                  onPressed: () => _showSnackBar("비밀번호 찾기 기능은 곧 추가됩니다."),
                  child: const Text(
                    "비밀번호 찾기",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                // 계정이 없는 경우 회원가입
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("계정이 없으신가요? "),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                      child: const Text(
                        "회원가입",
                        style: TextStyle(color: Colors.blue),
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

  // 로그인 시도 함수
  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      _showSnackBar("아이디와 비밀번호를 입력해 주세요.");
      return;
    }

    // Provider를 통해 서버에 로그인 요청
    final success = await ref.read(authProvider.notifier).login(id, pw);

    if (success && mounted) {
      // 로그인 성공 시 홈 화면으로 이동 (스택 제거)
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else if (mounted) {
      _showSnackBar("로그인 실패: 정보를 다시 확인해 주세요.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
