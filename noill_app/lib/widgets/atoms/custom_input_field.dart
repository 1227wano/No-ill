// lib/widgets/atoms/custom_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/color_constants.dart';

/// 공통 입력 필드 위젯
///
/// [label]: 입력 필드 위의 레이블 텍스트
/// [hintText]: placeholder 텍스트
/// [controller]: TextEditingController
/// [errorText]: 에러 메시지 (null이면 표시 안 함)
/// [obscureText]: 비밀번호 입력 필드 여부
/// [readOnly]: 읽기 전용 여부
/// [enabled]: 활성화 여부 (false면 입력 불가, 회색 처리)
/// [suffixIcon]: 오른쪽에 표시할 아이콘
/// [onSubmitted]: 엔터키 입력 시 실행될 콜백
/// [keyboardType]: 키보드 타입
/// [inputFormatters]: 입력 형식 제한
/// [maxLength]: 최대 입력 길이
class CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final FocusNode? focusNode;

  const CustomInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? NoIllColors.textMain : NoIllColors.textBody,
          ),
        ),
        const SizedBox(height: 8),

        // 입력 필드
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          focusNode: focusNode,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? NoIllColors.textMain : NoIllColors.textBody,
          ),
          decoration: InputDecoration(
            // 기본 스타일
            filled: true,
            fillColor: _getFillColor(),

            // 테두리
            border: _buildBorder(NoIllColors.textBody.withOpacity(0.3)),
            enabledBorder: _buildBorder(NoIllColors.textBody.withOpacity(0.3)),
            focusedBorder: _buildBorder(NoIllColors.primary, width: 2),
            disabledBorder: _buildBorder(NoIllColors.textBody.withOpacity(0.2)),
            errorBorder: _buildBorder(NoIllColors.danger),
            focusedErrorBorder: _buildBorder(NoIllColors.danger, width: 2),

            // 힌트 및 에러
            hintText: hintText,
            hintStyle: TextStyle(
              color: NoIllColors.textBody.withOpacity(0.6),
              fontSize: 16,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              color: NoIllColors.danger,
              fontSize: 12,
            ),

            // 아이콘
            suffixIcon: suffixIcon,

            // 패딩
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            // maxLength 카운터 숨기기
            counterText: '',
          ),
        ),
      ],
    );
  }

  /// 입력 필드 배경색 결정
  Color _getFillColor() {
    if (!enabled) {
      return Colors.grey.shade100;
    }
    if (readOnly) {
      return Colors.grey.shade50;
    }
    return Colors.white.withOpacity(0.6);
  }

  /// 테두리 스타일 생성
  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
