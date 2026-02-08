// lib/screens/auth/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/logger.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/asset_constants.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/main_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _logger = AppLogger('SplashScreen');
  bool _showWelcomeUI = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _checkAuthStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    await ref.read(authProvider.notifier).checkAuthStatus();

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      _logger.info('인증된 상태 - 메인 화면으로 이동');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
      return;
    }

    _logger.info('미인증 상태 - 웰컴 화면 표시');
    if (mounted) {
      setState(() => _showWelcomeUI = true);
      _fadeController.forward();
    }
  }

  void _handleStart() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _handleLogin() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _showWelcomeUI
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildWelcomeUI(),
                )
              : _buildLogoOnly(),
        ),
      ),
    );
  }

  Widget _buildWelcomeUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30.h),

          // -- 로고 --
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬 맞춤
            children: [
              Transform.translate(
                offset: Offset(-8.w, 0), // 숫자를 조절하며 텍스트와 수직선을 맞추세요.
                child: Image.asset(
                  NoIllAssets.logo,
                  width: 100.sp,
                  height: 100.sp,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                "No-ill",
                style: TextStyle(
                  fontFamily: 'KERIS',
                  fontWeight: FontWeight.w800,
                  fontSize: 26.sp,
                  color: NoIllColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h), // 👈 16.h ~ 24.h 사이에서 조절해 보세요.
          // -- 타이틀 --
          Text(
            "환영합니다!",
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: NoIllColors.textMain,
              letterSpacing: -0.8,
            ),
          ),

          SizedBox(height: 8.h),
          Text(
            "어르신의 스마트한\n동반자, 노일입니다.",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: NoIllColors.textMain.withValues(alpha: 0.85),
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),

          // SizedBox(height: 14.h),
          // Text(
          //   "연결과 안심으로 든든한 내일을\n함께 만들어가요.",
          //   style: TextStyle(
          //     fontSize: 15.sp,
          //     color: NoIllColors.textBody,
          //     height: 1.6,
          //   ),
          // ),

          // const Spacer(flex: 1),

          // -- 로봇 캐릭터 --
          Flexible(
            flex: 12,
            child: Center(
              child: Image.asset(
                NoIllAssets.robot,
                width: 0.75.sw,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // -- 버튼 섹션 --
          SizedBox(
            width: double.infinity,
            height: 58.h,
            child: ElevatedButton(
              onPressed: _handleStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: NoIllColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                "시작하기",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          SizedBox(
            width: double.infinity,
            height: 58.h,
            child: OutlinedButton(
              onPressed: _handleLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: NoIllColors.textMain,
                side: BorderSide(color: NoIllColors.border, width: 1.2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                "이미 계정이 있어요",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildLogoOnly() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(NoIllAssets.logo, width: 80.sp),
          SizedBox(height: 20.h),
          SizedBox(
            width: 24.sp,
            height: 24.sp,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: NoIllColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
