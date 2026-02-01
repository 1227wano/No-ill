// lib/screens/onboarding/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:noill_app/screens/auth/signup_screen.dart';
import 'package:noill_app/screens/main_screen.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import 'package:noill_app/widgets/atoms/solid_button.dart'; // 기존에 쓰시던 버튼 위젯
import '../../core/constants/color_constants.dart';
import '../../core/constants/asset_constants.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showWelcomeUI = false; // 로그인 안 되어 있을 때만 UI 노출

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    const storage = FlutterSecureStorage();
    // 1. 저장된 토큰을 읽어옵니다. (매우 짧은 시간 소요)
    final token = await storage.read(key: 'accessToken');

    if (!mounted) return;

    if (token != null) {
      // ✅ [시나리오 1] 토큰이 있으면 '즉시' 메인 화면으로 이동합니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // ✅ [시나리오 2] 토큰이 없으면 그제야 웰컴 UI를 화면에 그립니다.
      setState(() => _showWelcomeUI = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // 배경 그라데이션이 보이도록
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _showWelcomeUI ? _buildWelcomeUI() : _buildLogoOnly(),
          ),
        ),
      ),
    );
  }

  // --- 1. 로그인 기록이 없을 때 보여주는 웰컴 UI ---
  Widget _buildWelcomeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // 상단 로고 (이미지의 NoIll 로고 부분)
        Row(
          children: [
            Image.asset(NoIllAssets.logo, width: 24), // CI 아이콘
            const SizedBox(width: 8),
            const Text(
              "NoIll",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 48),
        // 메인 타이틀
        const Text(
          "환영합니다!\n어르신의 스마트한\n동반자, 노일입니다.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // 서브 타이틀
        Text(
          "연결과 안심으로 든든한 내일을\n함께 만들어가요.",
          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
        ),
        const Spacer(),
        // 🤖 로봇 캐릭터 이미지 (중앙 배치)
        Center(
          child: Image.asset(
            NoIllAssets.robot, // 💡 AssetConstants에 로봇 이미지 경로가 있어야 함
            width: MediaQuery.of(context).size.width * 0.7,
          ),
        ),
        const Spacer(),
        // 하단 버튼 섹션
        SolidButton(
          text: "시작하기",
          onPressed: () {
            // 회원가입이나 기기등록 온보딩으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  const TextSpan(text: "이미 계정이 있나요? "),
                  TextSpan(
                    text: "로그인",
                    style: TextStyle(
                      color: NoIllColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- 2. 자동 로그인 중일 때 잠깐 보여주는 기본 로고 ---
  Widget _buildLogoOnly() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(NoIllAssets.logo, width: 120),
          const SizedBox(height: 24),
          const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }
}
