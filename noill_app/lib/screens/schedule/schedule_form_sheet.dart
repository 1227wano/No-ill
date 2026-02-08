import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import '../../models/schedule_model.dart';
import '../../providers/care_provider.dart';
import '../../providers/schedule_provider.dart'; // petId를 가져오기 위한 프로바이더

class ScheduleFormSheet extends ConsumerStatefulWidget {
  final ScheduleModel? schedule; // 수정 모드일 경우 전달받음

  const ScheduleFormSheet({super.key, this.schedule});

  @override
  ConsumerState<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<ScheduleFormSheet> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool get isEditMode => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    // 초기값 설정: 수정 모드면 기존 데이터, 아니면 현재 시간 기준
    final initialDateTime =
        widget.schedule?.schTime ??
        DateTime.now().add(const Duration(minutes: 10));
    _selectedDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(initialDateTime);

    _nameController.text = widget.schedule?.schName ?? "";
    _memoController.text = widget.schedule?.schMemo ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 1. 📅 날짜 선택기
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // 오늘 이전 날짜는 선택 불가
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 2. ⏰ 시간 선택기
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // 🗑️ 일정 삭제 로직
  void _onDelete() async {
    final scheduleId = widget.schedule?.id;
    if (scheduleId == null) return;

    // 삭제 전 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("일정 삭제"),
        content: const Text("이 일정을 정말 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ 요청하신 대로 petId를 함께 보낼 수 있도록 처리
      // 단, removeSchedule이 id만 받도록 설계되어 있다면
      // 아래와 같이 호출하고 서비스 레이어에서 petId를 추가해야 합니다.
      final success = await ref
          .read(scheduleNotifierProvider.notifier)
          .removeSchedule(scheduleId);

      if (mounted && success) {
        Navigator.pop(context);
      }
    }
  }

  void _onSave() async {
    // 날짜와 시간을 하나의 DateTime 객체로 결합
    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 💡 [검증] 서버 400 에러 방지를 위한 미래 시간 체크
    if (finalDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🚨 일정은 현재 시간보다 이후여야 합니다.")));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("일정 제목을 입력해주세요.")));
      return;
    }

    final petId = ref.read(selectedPetIdProvider); // 현재 선택된 어르신 ID
    if (petId == null) return;

    final schedule = ScheduleModel(
      id: widget.schedule?.id,
      petNo: widget.schedule?.petNo ?? 0,
      schName: _nameController.text.trim(),
      schTime: finalDateTime,
      schMemo: _memoController.text.trim(),
      schStatus: widget.schedule?.schStatus ?? "PENDING",
    );

    bool success = false;
    if (isEditMode) {
      success = await ref
          .read(scheduleNotifierProvider.notifier)
          .editSchedule(schedule, petId);
    } else {
      success = await ref
          .read(scheduleNotifierProvider.notifier)
          .addSchedule(schedule, petId);
    }

    if (mounted && success) {
      Navigator.pop(context); // 성공 시 시트 닫기
    }
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEditMode ? "일정 수정" : "새 일정 등록",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "어떤 일정인가요?",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_calendar),
              ),
            ),
            const SizedBox(height: 15),

            // 날짜/시간 선택 섹션
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "날짜",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "시간",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "상세 메모 (선택사항)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 25),

            // --- 버튼 섹션 (삭제 버튼 추가) ---
            Row(
              children: [
                if (isEditMode) ...[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NoIllColors.danger,
                        side: const BorderSide(color: NoIllColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text("삭제"),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _onSave,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: NoIllColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(isEditMode ? "수정 완료" : "일정 추가하기"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
