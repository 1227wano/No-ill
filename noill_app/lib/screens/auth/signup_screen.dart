// 회원가입 페이지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/screens/main_screen.dart';
import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_models.dart';
import '../onboarding/device_pairing_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 가입 완료 팝업 함수
  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("환영합니다!", textAlign: TextAlign.center),
        content: const Text(
          "서비스 이용을 위해서는 로봇 등록이 필요합니다.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                SolidButton(
                  text: "로봇 등록하기",
                  onPressed: () {
                    Navigator.pop(dialogContext); // 1. 팝업창 닫기
                    // 2. 기기 연동 화면으로 이동 (build 메서드의 context 사용)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevicePairingScreen(),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // 팝업창 닫기
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text("나중에 등록하기"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    final id = _idController.text.trim();
    final password = _pwController.text.trim();
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    // 로그: 서버로 넘길 데이터 확인
    print("회원가입 데이터 수집:");
    print("userId: $id");
    print("userPassword: $password");
    print("userName: $name");
    print("userAddress: $address");
    print("userPhone: $phone");

    if (id.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        address.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 필드를 입력해주세요.")));
      return;
    }

    final request = SignupRequest(
      userId: id,
      userPassword: password,
      userName: name,
      userAddress: address,
      userPhone: phone,
    );

    final success = await ref.read(authProvider.notifier).signUp(request);

    if (success) {
      _showWelcomeDialog(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("회원가입에 실패했습니다. 다시 시도해주세요.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DualDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("회원가입"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              CustomInputField(
                label: "아이디",
                hintText: "아이디를 입력하세요",
                controller: _idController,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: "비밀번호",
                hintText: "비밀번호를 입력하세요",
                obscureText: true,
                controller: _pwController,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: "이름",
                hintText: "이름을 입력하세요",
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: "주소",
                hintText: "주소를 입력하세요",
                controller: _addressController,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: "전화번호",
                hintText: "전화번호를 입력하세요",
                controller: _phoneController,
              ),
              const SizedBox(height: 16),
              SolidButton(text: "가입하기", onPressed: _handleSignup),
            ],
          ),
        ),
      ),
    );
  }
}
