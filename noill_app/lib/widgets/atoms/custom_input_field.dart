// 입력 필드 위젯

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;

  const CustomInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.errorText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 레이블
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: NoIllColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        // 2. 입력창
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 16, color: NoIllColors.textMain),
          decoration: InputDecoration(
            // 스타일
            filled: true,
            fillColor: Colors.white.withOpacity(0.6), // 배경 살짝 비침
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none, // 기본 테두리 없음
            ),
            // 힌트
            hintText: hintText,
            hintStyle: const TextStyle(color: NoIllColors.textBody),
            errorText: errorText, // 에러 메시지가 있으면 빨간색으로 자동 표시
            // 에러 발생 시 테두리 스타일
            errorStyle: const TextStyle(color: NoIllColors.danger),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NoIllColors.danger, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NoIllColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
