// 스플래쉬 화면: 앱 시작 시 잠깐 보여주는 화면

import 'package:flutter/material.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../core/constants/color_constants.dart';
import 'login_screen.dart';
import '../../core/constants/asset_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2초 대기 후 로그인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: NoIllColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지 (assets/icons/ci_noill.png 경로에 파일이 있어야 함)
              Image.asset(NoIllAssets.logo, width: 120),
              SizedBox(height: 16),
              Text(
                "고통이 없는 세상, No-ill",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NoIllColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
