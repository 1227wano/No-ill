// 상태(state)와 타입(type)에 따라 유연하게 변하는 버튼
// 화면 개발 시 아래와 같이 간단하게 호출해서 사용 가능
// 일반 확인 버튼
// SolidButton(
//   text: '로그인',
//   onPressed: () => print('로그인 클릭'),
// ),

// // 긴급 상황 버튼 (코랄 레드)
// SolidButton(
//   text: '즉시 신고',
//   isDanger: true,
//   onPressed: () => print('신고 실행'),
// ),

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class SolidButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동으로 Disabled 상태가 됩니다.
  final bool isDanger;

  const SolidButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // Danger 여부에 따라 배경색 결정
        backgroundColor: isDanger ? NoIllColors.danger : NoIllColors.primary,
        // Disabled 상태일 때의 배경색 설정
        disabledBackgroundColor: NoIllColors.border,
        disabledForegroundColor: NoIllColors.textBody,
        // 텍스트 스타일: 버튼 내부는 흰색 고정
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(48), // 피그마 규격 반영
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
