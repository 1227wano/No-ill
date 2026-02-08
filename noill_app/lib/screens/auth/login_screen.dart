// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAuthLoadingProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;
      if (next.isAuthenticated) {
        _showSnackBar('로그인 성공! 환영합니다 ${next.userData?.userName ?? ''}님', isError: false);
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
      if (next.hasError && next.errorMessage != null) {
        _showSnackBar(next.errorMessage!, isError: true);
      }
    });

    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // -- 상단 바 --
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: NoIllColors.textMain),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // -- 본문 (스크롤) --
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12.h),

                      // 타이틀
                      Text(
                        "로그인",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: NoIllColors.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "어르신의 안전한 내일을\n노일이 함께 지킵니다.",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: NoIllColors.textBody,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // 아이디
                      CustomInputField(
                        label: "아이디",
                        hintText: "아이디를 입력하세요",
                        controller: _idController,
                        enabled: !isLoading,
                      ),
                      SizedBox(height: 20.h),

                      // 비밀번호
                      CustomInputField(
                        label: "비밀번호",
                        hintText: "비밀번호를 입력하세요",
                        obscureText: true,
                        controller: _pwController,
                        enabled: !isLoading,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      SizedBox(height: 36.h),

                      // 로그인 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NoIllColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: NoIllColors.border,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 22.sp,
                                  height: 22.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "로그인",
                                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // 하단 링크
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _showSnackBar("비밀번호 찾기 기능은 곧 추가됩니다.", isError: false),
                            child: Text(
                              "비밀번호 찾기",
                              style: TextStyle(
                                color: NoIllColors.textBody,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12.h,
                            color: NoIllColors.border,
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                                    ),
                            child: Text(
                              "회원가입",
                              style: TextStyle(
                                color: NoIllColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 키보드 여백
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 로그인 처리
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    if (!_validateInput(id, pw)) return;

    await ref.read(authProvider.notifier).login(id, pw);
  }

  bool _validateInput(String id, String pw) {
    if (id.isEmpty) {
      _showSnackBar('아이디를 입력해주세요', isError: true);
      return false;
    }
    if (pw.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요', isError: true);
      return false;
    }
    if (id.length < 3) {
      _showSnackBar('아이디는 3자 이상이어야 합니다', isError: true);
      return false;
    }
    if (pw.length < 4) {
      _showSnackBar('비밀번호는 4자 이상이어야 합니다', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? NoIllColors.danger : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}
