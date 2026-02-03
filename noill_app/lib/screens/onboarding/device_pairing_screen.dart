import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/screens/main_screen.dart';
import 'package:noill_app/widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/otp_input.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/pet_provider.dart';
import '../../providers/care_provider.dart';
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
  final _petNameController = TextEditingController(text: "노일이");

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
    _petNameController.dispose();
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
        body: SingleChildScrollView(
          // 키보드 올라와도 화면이 올라가도록
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

              const SizedBox(height: 12),
              CustomInputField(
                label: '로봇펫의 이름을 지어주세요.',
                controller: _petNameController,
                hintText: "노일이",
              ),

              const SizedBox(height: 32),

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
              const SizedBox(height: 24),

              // ✅ 수정: 5자리가 입력되었을 때만 버튼이 활성화되도록 로직 연결
              SolidButton(
                text: "기기 등록 및 계속하기",
                onPressed: _inputSerial.length == 5
                    ? () async {
                        // 1. 로딩 표시 (선택 사항이지만 UX상 권장)
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        // 2. 서버 연동 시도 (POST /api/auth/pets/login)
                        final petData = await ref
                            .read(petServiceProvider)
                            .connectPet(_inputSerial);

                        if (!mounted) return;
                        Navigator.pop(context); // 로딩 창 닫기

                        if (petData != null && petData.careName.isNotEmpty) {
                          // 💡 [시나리오 A] 이미 등록된 어르신인 경우 -> 확인 팝업 (인증 UX)
                          _showConfirmAccountDialog(context, petData);
                        } else {
                          // 💡 [시나리오 B] 신규 기기인 경우 -> 기존 등록 화면 이동
                          ref
                              .read(petRegistrationProvider.notifier)
                              .updatePetName(_petNameController.text);
                          ref
                              .read(petRegistrationProvider.notifier)
                              .updatePetId(_inputSerial);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ElderlyProfileRegistrationScreen(),
                            ),
                          );
                        }
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

  void _showConfirmAccountDialog(BuildContext context, data) {
    // 👈 'data'로 받음
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text("어르신 기기 확인")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("입력하신 번호로 등록된 정보를 찾았습니다."),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    data.careName, // 👈 'info' 대신 'data' 사용
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // 💡 모델에 petAddress가 없다면 petId를 임시로 보여주세요.
                    "기기 번호: ${data.petId}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("이 어르신을 함께 관리하시겠습니까?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("다시 입력"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A85B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // ✅ 1. 목록 새로고침 (서버에 이미 등록된 경우이므로 싱크만 맞춤)
              ref.invalidate(careListProvider);

              // ✅ 2. 현재 선택된 어르신 변경
              ref.read(selectedPetIdProvider.notifier).state = data.petId;

              // ✅ 3. 메인으로 점프
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "예, 연결합니다",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
