// 환영합니다

// lib/widgets/molecules/welcome_dialog.dart

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../atoms/solid_button.dart';

void showWelcomeDialog(BuildContext context, VoidCallback onStart) {
  showDialog(
    context: context,
    barrierDismissible: false, // 팝업 밖을 눌러도 닫히지 않게 설정
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 축하 아이콘 (노일의 상징적인 하트나 로봇 아이콘)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NoIllColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                size: 48,
                color: NoIllColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // 2. 환영 문구
            const Text(
              "가족이 되신 것을\n환영합니다!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "이제 노일(No-ill)이 24시간\n어르신의 곁을 지키며\n안심을 전해드릴게요.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),

            // 3. 시작하기 버튼
            SolidButton(
              text: "서비스 시작하기",
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                onStart(); // 메인 화면으로 이동하는 콜백 실행
              },
            ),
          ],
        ),
      ),
    ),
  );
}
