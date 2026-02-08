// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpostal/kpostal.dart';

import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';

import '../../providers/auth_provider.dart';
import '../../models/auth_model.dart';
import 'package:noill_app/screens/main_screen.dart';
import '../onboarding/device_pairing_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        "회원가입",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: NoIllColors.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "보호자님의 소중한 정보는\n안전하게 관리됩니다.",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: NoIllColors.textBody,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 36.h),

                      // 아이디
                      CustomInputField(
                        label: '아이디',
                        hintText: '아이디를 입력하세요',
                        controller: _idController,
                        enabled: !_isSubmitting,
                      ),
                      SizedBox(height: 18.h),

                      // 비밀번호
                      CustomInputField(
                        label: '비밀번호',
                        hintText: '비밀번호를 입력하세요',
                        obscureText: true,
                        controller: _pwController,
                        enabled: !_isSubmitting,
                      ),
                      SizedBox(height: 18.h),

                      // 이름
                      CustomInputField(
                        label: '이름',
                        hintText: '이름을 입력하세요',
                        controller: _nameController,
                        enabled: !_isSubmitting,
                      ),
                      SizedBox(height: 18.h),

                      // 주소
                      CustomInputField(
                        label: '주소',
                        hintText: '주소를 검색해 주세요',
                        controller: _addressController,
                        readOnly: true,
                        enabled: !_isSubmitting,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search, color: NoIllColors.textBody),
                          onPressed: _isSubmitting ? null : _openAddressSearch,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // 상세 주소
                      CustomInputField(
                        label: '상세 주소',
                        hintText: '동, 호수 등을 입력하세요',
                        controller: _detailAddressController,
                        enabled: !_isSubmitting,
                      ),
                      SizedBox(height: 18.h),

                      // 전화번호
                      CustomInputField(
                        label: '전화번호',
                        hintText: '전화번호를 입력하세요',
                        controller: _phoneController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 36.h),

                      // 가입 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NoIllColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: NoIllColors.border,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 22.sp,
                                  height: 22.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "가입하기",
                                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      // 키보드 여백
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40.h),
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
  // 회원가입 처리
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleSignup() async {
    if (_isSubmitting) return;

    final id = _idController.text.trim();
    final password = _pwController.text.trim();
    final name = _nameController.text.trim();
    final baseAddr = _addressController.text.trim();
    final detailAddr = _detailAddressController.text.trim();
    final phone = _phoneController.text.trim();
    final fullAddress = '$baseAddr $detailAddr'.trim();

    final validationError = _validate(
      id: id, password: password, name: name, address: fullAddress, phone: phone,
    );

    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    final request = SignupRequest(
      userId: id,
      userPassword: password,
      userName: name,
      userAddress: fullAddress,
      userPhone: phone,
      pets: [],
    );

    setState(() => _isSubmitting = true);

    final success = await ref.read(authProvider.notifier).signUp(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showWelcomeDialog(context);
    } else {
      _showSnackBar('회원가입에 실패했습니다. 다시 시도해주세요.', isError: true);
    }
  }

  String? _validate({
    required String id,
    required String password,
    required String name,
    required String address,
    required String phone,
  }) {
    if (id.isEmpty || password.isEmpty || name.isEmpty || address.isEmpty || phone.isEmpty) {
      return '모든 필드를 입력해주세요.';
    }
    if (id.length < 3) return '아이디는 3자 이상이어야 합니다.';
    if (password.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
    if (!RegExp(r'^[0-9]{9,}$').hasMatch(phone.replaceAll('-', ''))) {
      return '전화번호 형식을 확인해주세요.';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 주소 검색
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _openAddressSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          useLocalServer: true,
          callback: (Kpostal result) {
            setState(() {
              _addressController.text = result.address;
            });
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 다이얼로그 / 스낵바
  // ═══════════════════════════════════════════════════════════════════════

  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 8.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_outlined, size: 48.sp, color: NoIllColors.primary),
            SizedBox(height: 16.h),
            Text(
              '환영합니다!',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: NoIllColors.textMain,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '서비스 이용을 위해서는\n로봇 등록이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: NoIllColors.textBody,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NoIllColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text(
                  '로봇 등록하기',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              },
              child: Text(
                '나중에 등록하기',
                style: TextStyle(fontSize: 14.sp, color: NoIllColors.textBody),
              ),
            ),
          ],
        ),
      ),
    );
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
