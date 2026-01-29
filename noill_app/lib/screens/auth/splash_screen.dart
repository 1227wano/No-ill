// 스플래쉬 화면: 앱 시작 시 잠깐 보여주는 화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:noill_app/screens/main_screen.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../core/constants/color_constants.dart';
import 'login_screen.dart';
import '../../core/constants/asset_constants.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 잠깐 보여주기 위해 약간의 지연을 둡니다.
    await Future.delayed(const Duration(milliseconds: 700));

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'accessToken');

    if (!mounted) return;

    if (token != null) {
      // 💡 토큰 있으면 바로 홈으로!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // 💡 없으면 로그인 화면으로!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: NoIllColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지 (assets/icons/ci_noill.png 경로에 파일이 있어야 함)
              Image.asset(NoIllAssets.logo, width: 120),
              const SizedBox(height: 16),
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
