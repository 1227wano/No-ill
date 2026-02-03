import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/schedule_model.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/care_provider.dart'; // 어르신 정보 조회를 위한 프로바이더

class ScheduleFormSheet extends ConsumerStatefulWidget {
  final ScheduleModel? initialSchedule; // 수정 시에는 기존 데이터를 넘겨받습니다.

  const ScheduleFormSheet({super.key, this.initialSchedule});

  @override
  ConsumerState<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<ScheduleFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    // ✅ 수정 모드와 등록 모드 구분
    _nameController = TextEditingController(
      text: widget.initialSchedule?.schName ?? "",
    );
    _memoController = TextEditingController(
      text: widget.initialSchedule?.schMemo ?? "",
    );

    // 초기 시간 설정: 수정 시 기존 시간, 등록 시 현재 선택된 날짜의 다음 정각
    final baseDate = ref.read(selectedDateProvider);
    _selectedTime =
        widget.initialSchedule?.schTime ??
        DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          DateTime.now().hour + 1,
          0,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 💡 타임피커 호출
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  // 💾 저장 로직
  void _save() async {
    final selectedPet = ref.read(selectedPetProvider); // 어르신 전체 정보를 가진 객체
    final int petNo = selectedPet?.petNo ?? 0;
    final String petId = selectedPet?.petId ?? "";

    final schedule = ScheduleModel(
      petNo: petNo, // 여기서 자동으로 서버용 번호가 들어갑니다.
      schName: _nameController.text,
      schTime: _selectedTime,
      schMemo: _memoController.text,
    );

    if (widget.initialSchedule == null) {
      await ref.read(scheduleNotifierProvider.notifier).addSchedule(schedule);
    } else {
      await ref.read(scheduleNotifierProvider.notifier).editSchedule(schedule);
    }

    if (mounted) Navigator.pop(context); // 성공 시 바텀시트 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialSchedule == null ? "새 일정 등록" : "일정 수정",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "일정 이름 (예: 혈압약 복용)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          ListTile(
            title: const Text("시간 설정"),
            trailing: Text(
              DateFormat('HH:mm').format(_selectedTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            onTap: _pickTime,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _memoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "메모 (선택 사항)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(widget.initialSchedule == null ? "등록하기" : "수정 완료"),
          ),
        ],
      ),
    );
  }
}
