import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS 스타일 위젯을 위해 필요
import '../../../core/constants/color_constants.dart';
import '../../../widgets/atoms/solid_button.dart';
import '../../../widgets/atoms/custom_input_field.dart';

class ScheduleFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;

  const ScheduleFormModal({super.key, this.isEdit = false, this.initialData});

  @override
  State<ScheduleFormModal> createState() => _ScheduleFormModalState();
}

class _ScheduleFormModalState extends State<ScheduleFormModal> {
  // 선택된 시간을 관리하는 상태git
  late DateTime selectedTime; // 초기 시간

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // 현재 분을 5로 나눈 뒤 반올림하고 다시 5를 곱해 '5의 배수'로 만듭니다.
    int roundedMinute = (now.minute / 5).round() * 5;

    selectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      roundedMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isEdit ? "일정 수정" : "새 일정 추가",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          const CustomInputField(label: "내용", hintText: "예: 아침 약 복용, 산책 등"),
          const SizedBox(height: 24),

          const Text(
            "시간 설정",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // --- 아이폰 스타일 스크롤 타임 피커 영역 ---
          Container(
            height: 180, // 피커의 적절한 높이 설정
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time, // 시간/분만 선택
              initialDateTime: selectedTime,
              onDateTimeChanged: (DateTime newTime) {
                setState(() {
                  selectedTime = newTime;
                });
              },
              use24hFormat: false, // 오전/오후 구분
              minuteInterval: 5, // 5분 단위 스크롤 (조절 가능)
            ),
          ),

          // ---------------------------------------
          const SizedBox(height: 32),

          Row(
            children: [
              if (widget.isEdit) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NoIllColors.danger,
                      side: const BorderSide(color: NoIllColors.danger),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("삭제"),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SolidButton(
                  text: widget.isEdit ? "수정 완료" : "등록하기",
                  onPressed: () {
                    // 선택된 시간과 데이터를 저장하는 로직
                    print(
                      "선택된 시간: ${selectedTime.hour}:${selectedTime.minute}",
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
