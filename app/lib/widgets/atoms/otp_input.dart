// 일련번호 입력 위젯

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class OtpInput extends StatelessWidget {
  const OtpInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) => _buildOtpBox(context, index)),
    );
  }

  Widget _buildOtpBox(BuildContext context, int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        onChanged: (value) {
          if (value.length == 1 && index < 5)
            FocusScope.of(context).nextFocus(); // 다음 칸 이동
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "", // 글자수 표시 제거
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: NoIllColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: NoIllColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
