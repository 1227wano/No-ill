// 어르신 정보 수정

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/atoms/solid_button.dart';
import '../../widgets/atoms/custom_input_field.dart';

class ElderlyProfileEditScreen extends StatelessWidget {
  const ElderlyProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LightDiffusionBackground(
      //
      child: Scaffold(
        backgroundColor: Colors.transparent, //
        appBar: AppBar(
          title: const Text("어르신 정보 수정"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. 프로필 사진 수정
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(
                        'assets/images/user_profile.png',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
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
              ),
              const SizedBox(height: 32),

              // 2. 입력 필드 그룹 (기존 정보 반영)
              const CustomInputField(label: "성함", hintText: "Mary Jane"),
              const SizedBox(height: 20),
              const CustomInputField(label: "생년월일", hintText: "1945. 01. 01"),
              const SizedBox(height: 20),
              const CustomInputField(
                label: "거주 주소",
                hintText: "서울특별시 OO구 OO로 123",
              ),
              const SizedBox(height: 20),
              const CustomInputField(
                label: "비상 연락처",
                hintText: "010-1234-5678",
              ),

              const SizedBox(height: 40),

              // 3. 저장 및 삭제 버튼
              SolidButton(
                text: "수정 내용 저장",
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showDeleteConfirmDialog(context),
                child: const Text(
                  "기기 연동 해제 및 정보 삭제",
                  style: TextStyle(
                    color: NoIllColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("정말 삭제하시겠습니까?"),
        content: const Text("어르신의 모든 기록과 로봇펫 연동 정보가 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫기
              Navigator.pop(context); // 수정 화면 닫기
              // 여기서 실제 삭제 로직 수행
            },
            child: const Text(
              "삭제",
              style: TextStyle(color: NoIllColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
