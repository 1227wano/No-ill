import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class OtpInput extends StatefulWidget {
  // 💡 상태 관리를 위해 StatefulWidget으로 변경
  final int length;
  final ValueChanged<String> onChanged; // 💡 부모에게 값을 전달할 통로

  const OtpInput({super.key, this.length = 5, required this.onChanged});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  // 1. 각 칸의 글자를 제어할 컨트롤러 리스트
  late List<TextEditingController> _controllers;
  // 2. 각 칸의 포커스를 제어할 노드 리스트
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // 💡 모든 칸의 값을 합쳐서 부모에게 보고하는 함수
  void _onValuesChanged() {
    String fullCode = _controllers.map((e) => e.text).join();
    widget.onChanged(fullCode);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) => _buildOtpBox(index)),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        onChanged: (value) {
          // 값이 입력되면 다음 칸으로, 지워지면 이전 칸으로 자동 이동
          if (value.length == 1 && index < widget.length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          _onValuesChanged(); // 👈 값이 변할 때마다 부모에게 전달!
        },
        textAlign: TextAlign.center,
        // 💡 영어+숫자 조합이므로 text 타입으로 변경 (number는 숫자만 나옴)
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters, // 자동으로 대문자 변환
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
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
