import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 추가
import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/gradient_background.dart';
import '../../providers/pet_provider.dart'; // 👈 추가
import '../main_screen.dart';
import '../../widgets/molecules/welcome_dialog.dart';

class ElderlyProfileRegistrationScreen extends ConsumerStatefulWidget {
  // 👈 Consumer로 변경
  const ElderlyProfileRegistrationScreen({super.key});

  @override
  ConsumerState<ElderlyProfileRegistrationScreen> createState() =>
      _ElderlyProfileRegistrationScreenState();
}

class _ElderlyProfileRegistrationScreenState
    extends ConsumerState<ElderlyProfileRegistrationScreen> {
  // 1. 입력 제어를 위한 컨트롤러 선언
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    // 💡 메모리 누수 방지를 위해 컨트롤러 해제 (PM의 꼼꼼함!)
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 2. 등록 실행 함수
  Future<void> _handleRegistration() async {
    // 입력값 유효성 검사
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 항목을 입력해주세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final notifier = ref.read(petRegistrationProvider.notifier);

    // [Step 1] 입력값들을 Provider에 업데이트
    // _nameController.text → careName (어르신 성함)
    // _addressController.text → petAddress (거주 주소)
    // _phoneController.text → petPhone (비상 연락처)
    notifier.updateProfile(
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
    );

    // [Step 2] 서버로 전송 (모든 정보가 합쳐집니다)
    // petId, petName (기기 등록 화면)
    // careName, petAddress, petPhone (어르신 등록 화면)
    // petBirth (자동 설정: 현재 날짜)
    final success = await notifier.submit();

    if (success) {
      if (mounted) {
        showWelcomeDialog(context, () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        });
      }
    } else {
      // 실패 시 에러 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("등록에 실패했습니다. 다시 시도해주세요."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "이제 노일(No-ill)이\n누구를 지켜드릴까요?",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // 프로필 사진 섹션 (기존 유지)
                _buildProfileImageSection(),

                const SizedBox(height: 48),

                // 💡 컨트롤러를 각 입력 필드에 연결
                CustomInputField(
                  label: "성함",
                  hintText: "어르신의 성함을 입력해주세요.",
                  controller: _nameController, // 👈 연결
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: "거주 주소",
                  hintText: "어르신이 계신 상세 주소를 입력해주세요.",
                  controller: _addressController, // 👈 연결
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: "비상 연락처",
                  hintText: "010-0000-0000",
                  controller: _phoneController, // 👈 연결
                ),

                const SizedBox(height: 60),

                SolidButton(
                  text: "등록 완료하고 시작하기",
                  onPressed: _handleRegistration, // 👈 서버 전송 로직 실행
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_outline,
              size: 50,
              color: Colors.grey[300],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: NoIllColors.primary,
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
