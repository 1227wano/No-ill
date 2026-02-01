// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
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
    final authState = ref.watch(authProvider);

    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // 배경 그라데이션 유지를 위해 투명화
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            // 💡 키보드가 올라올 때 화면이 잘리지 않도록 함
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // 💡 당근마켓 스타일: 왼쪽 정렬
              children: [
                SizedBox(height: 20.h),
                // 메인 타이틀
                Text(
                  "안녕하세요!\n보호자님, 로그인해주세요.",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "어르신의 안전한 내일을 노일이 함께 지킵니다.",
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                ),
                SizedBox(height: 48.h),

                // 입력 섹션
                CustomInputField(
                  label: "아이디",
                  hintText: "ID를 입력하세요",
                  controller: _idController,
                ),
                SizedBox(height: 16.h),
                CustomInputField(
                  label: "비밀번호",
                  hintText: "비밀번호를 입력하세요",
                  obscureText: true,
                  controller: _pwController,
                ),
                SizedBox(height: 40.h),

                // 로그인 버튼
                SolidButton(
                  text: authState.isLoading ? "로그인 중..." : "로그인",
                  onPressed: authState.isLoading ? null : () => _handleLogin(),
                ),

                SizedBox(height: 24.h),

                // 하단 링크 섹션 (중앙 정렬 유지)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showSnackBar("비밀번호 찾기 기능은 곧 추가됩니다."),
                      child: Text(
                        "비밀번호 찾기",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12.h,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                      child: Text(
                        "회원가입",
                        style: TextStyle(
                          color: NoIllColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                // 키보드 여백 확보
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom + 20.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 로그인 시도 함수
  void _handleLogin() async {
    final id = _idController.text;
    final pw = _pwController.text;

    // success 변수 대신 상태를 확인하도록 변경하거나, login 함수가 bool을 주게 수정
    await ref.read(authProvider.notifier).login(id, pw);

    // 성공 여부는 authProvider의 status가 authenticated로 변했는지로 확인합니다.
    if (ref.read(authProvider).status == AuthStatus.authenticated && mounted) {
      // 홈으로 이동
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
