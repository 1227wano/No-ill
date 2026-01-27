// 기기 등록 화면
import 'package:flutter/material.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/otp_input.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../core/constants/color_constants.dart';
import 'elderly_profile_registration_screen.dart'; // 다음 단계 페이지

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFound = false; // 기기 발견 여부 상태

  @override
  void initState() {
    super.initState();
    // 펄스(Pulse) 애니메이션 설정
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 3초 후 기기를 찾은 것으로 시뮬레이션
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isFound = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "기기 연동",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "나의 기기 연동 상태",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // --- 애니메이션 카드 영역 ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: NoIllColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.1).animate(_controller),
                      child: Icon(
                        _isFound ? Icons.check_circle : Icons.sensors,
                        size: 64,
                        color: _isFound ? Colors.green : NoIllColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isFound ? "연결 가능한 로봇을 찾았습니다!" : "주변의 로봇을 찾는 중입니다...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isFound ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // --- 시리얼 번호 입력 영역 ---
              const Text(
                "기기 시리얼 번호 입력 (6자리)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "로봇 하단에 부착된 영어+숫자 조합 6자리를 입력해주세요.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // 6자리 입력을 위한 OTP Input 커스텀 호출
              const OtpInput(), // 내부적으로 6칸으로 구성되어 있다고 가정

              const Spacer(),

              SolidButton(
                text: "기기 등록 및 계속하기",
                onPressed: () {
                  // 등록 성공 시 다음 온보딩(어르신 프로필 등록)으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ElderlyProfileRegistrationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
