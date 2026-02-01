// 회원가입 페이지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:noill_app/widgets/atoms/gradient_background.dart';
import '../../widgets/atoms/custom_input_field.dart';
import '../../widgets/atoms/solid_button.dart';

import '../../providers/auth_provider.dart';
import '../../models/auth_models.dart';

import 'package:noill_app/screens/main_screen.dart';
import '../onboarding/device_pairing_screen.dart';
import 'address_search_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // 검색된 기본 주소
  final TextEditingController _detailAddressController =
      TextEditingController(); // 사용자가 직접 입력할 상세 주소
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
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
    // final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    // 1. 각 필드 값 가져오기
    final baseAddr = _addressController.text.trim();
    final detailAddr = _detailAddressController.text.trim();

    // 💡 두 주소를 합쳐서 '최종 주소' 생성
    final fullAddress = "$baseAddr $detailAddr".trim();

    // 로그: 서버로 넘길 데이터 확인
    print("회원가입 데이터 수집:");
    print("userId: $id");
    print("userPassword: $password");
    print("userName: $name");
    print("userAddress: $fullAddress");
    print("userPhone: $phone");

    if (id.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        fullAddress.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 필드를 입력해주세요.")));
      return;
    }

    // 2. 기존 모델(SignupRequest)에 합쳐진 주소 넣기
    final request = SignupRequest(
      userId: _idController.text.trim(),
      userPassword: _pwController.text.trim(),
      userName: _nameController.text.trim(),
      userAddress: fullAddress,
      userPhone: _phoneController.text.trim(),
      pets: [],
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          // 💡 로그인 화면과 동일한 뒤로 가기 버튼 스타일
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 💡 왼쪽 정렬 통일
              children: [
                SizedBox(height: 20.h),
                Text(
                  "처음 오셨나요?\n정보를 입력해주세요.",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "보호자님의 소중한 정보는 안전하게 관리됩니다.",
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                ),
                SizedBox(height: 40.h),

                // --- 입력 필드 섹션 ---
                CustomInputField(
                  label: "아이디",
                  hintText: "아이디를 입력하세요",
                  controller: _idController,
                ),
                SizedBox(height: 16.h),
                CustomInputField(
                  label: "비밀번호",
                  hintText: "비밀번호를 입력하세요",
                  obscureText: true,
                  controller: _pwController,
                ),
                SizedBox(height: 16.h),
                CustomInputField(
                  label: "이름",
                  hintText: "이름을 입력하세요",
                  controller: _nameController,
                ),
                SizedBox(height: 16.h),
                // --- UI 빌드 부분 (주소 섹션) ---
                CustomInputField(
                  label: "주소",
                  hintText: "주소를 검색해 주세요",
                  controller: _addressController,
                  readOnly: true, // 💡 직접 타이핑 방지
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      // 💡 작성하신 AddressSearchScreen 클래스로 이동합니다.
                      final DataModel? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressSearchScreen(),
                        ),
                      );

                      // 검색 결과가 있으면 컨트롤러에 값을 넣어줍니다.
                      if (result != null) {
                        setState(() {
                          _addressController.text = result.address;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                CustomInputField(
                  label: "상세 주소",
                  hintText: "나머지 주소를 입력하세요 (동, 호수 등)",
                  controller: _detailAddressController,
                ),
                SizedBox(height: 16.h),
                CustomInputField(
                  label: "전화번호",
                  hintText: "전화번호를 입력하세요",
                  controller: _phoneController,
                ),
                SizedBox(height: 40.h),

                // 가입하기 버튼
                SolidButton(text: "가입하기", onPressed: _handleSignup),

                // 키보드 대응 여백
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom + 40.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
