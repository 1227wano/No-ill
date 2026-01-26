import 'package:flutter/material.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/otp_input.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../core/constants/color_constants.dart';

class DevicePairingScreen extends StatelessWidget {
  const DevicePairingScreen({super.key});

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
              const SizedBox(height: 20),
              // 기기 연결 상태를 보여주는 카드 영역
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings_input_component,
                        size: 48,
                        color: NoIllColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "연결된 로봇을 찾고 있습니다...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "시리얼 번호 입력",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const OtpInput(),
              const Spacer(),
              SolidButton(
                text: "연동 완료",
                onPressed: () {
                  // 연동 성공 팝업 로직 호출
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
