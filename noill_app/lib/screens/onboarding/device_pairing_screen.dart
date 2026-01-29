import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/otp_input.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/pet_provider.dart';
import 'elderly_profile_registration_screen.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFound = false;
  String _inputSerial = ""; // 입력된 5자리 번호 저장

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
    return DualDiffusionBackground(
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

              // ✅ 수정: 긴 코드 대신 선언해두신 함수를 호출합니다.
              _buildStatusCard(),

              const SizedBox(height: 48),

              const Text(
                "기기 시리얼 번호 입력 (5자리)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "로봇 하단에 부착된 영어+숫자 조합 5자리를 입력해주세요.", // 6자리 -> 5자리 문구 수정
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ✅ 수정: OtpInput에 length와 onChanged를 연결합니다.
              OtpInput(
                length: 5,
                onChanged: (value) {
                  setState(() {
                    _inputSerial = value; // 여기서 5글자가 완성되면 버튼이 켜집니다!
                  });
                },
              ),
              const Spacer(),

              // ✅ 수정: 5자리가 입력되었을 때만 버튼이 활성화되도록 로직 연결
              SolidButton(
                text: "기기 등록 및 계속하기",
                onPressed: _inputSerial.length == 5
                    ? () {
                        // 1. Provider에 기기 번호(petId) 저장
                        ref
                            .read(petRegistrationProvider.notifier)
                            .updatePetId(_inputSerial);

                        // 2. 다음 단계(어르신 프로필 등록)로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ElderlyProfileRegistrationScreen(),
                          ),
                        );
                      }
                    : null, // 5자리가 아니면 버튼이 비활성화(회색) 됩니다.
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 클래스 내부에 잘 정의된 상태 카드 위젯 함수
  Widget _buildStatusCard() {
    return AnimatedContainer(
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
    );
  }
}
