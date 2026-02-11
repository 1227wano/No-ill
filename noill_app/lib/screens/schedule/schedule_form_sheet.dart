import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/schedule_model.dart';
import '../../providers/care_provider.dart';
import '../../providers/schedule_provider.dart';

class ScheduleFormSheet extends ConsumerStatefulWidget {
  final ScheduleModel? schedule;

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
    // 초기값 설정: 수정 모드면 기존 데이터(로컬 변환), 아니면 현재 시간 기준
    final initialDateTime =
        widget.schedule?.schTime.toLocal() ??
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onSave() async {
    // 1. 날짜와 시간 결합 (로컬 기준)
    final localDate = _selectedDate.toLocal();
    final finalDateTime = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 2. [수정] 서버 API 형식에 맞게 밀리초와 타임존 제거
    // 결과 예시: 2026-02-11T18:28:00
    final String formattedTime = finalDateTime
        .toIso8601String()
        .split('.')
        .first;

    // 3. 검증 로직
    if (finalDateTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 1)),
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🚨 일정은 현재 시간보다 이후여야 합니다.")));
      return;
    }

    final petId = ref.read(selectedPetIdProvider);
    if (petId == null) return;

    // 4. 모델 생성 시 schTime을 String으로 보낼 수 있도록 조정하거나
    // 모델의 toJson에서 형식을 맞추어야 합니다.
    final schedule = ScheduleModel(
      id: widget.schedule?.id,
      petNo: widget.schedule?.petNo ?? 0,
      schName: _nameController.text.trim(),
      schTime: finalDateTime, // 모델 내부에서 toJson 시 형식을 맞춘다고 가정
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라올 때 여백 확보
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, bottomInset + 20.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 콘텐츠 크기만큼만 차지 (오버플로우 방지)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 핸들러
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEditMode ? "일정 수정" : "새 일정 등록",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),

            // 입력 필드: 제목
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "어떤 일정인가요?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.edit_calendar),
              ),
            ),
            SizedBox(height: 16.h),

            // 날짜/시간 선택
            Row(
              children: [
                Expanded(
                  child: _buildPickerBox(
                    label: "날짜",
                    value: DateFormat('yyyy-MM-dd').format(_selectedDate),
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildPickerBox(
                    label: "시간",
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 입력 필드: 메모
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "상세 메모 (선택사항)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 32.h),

            // 하단 버튼
            Row(
              children: [
                if (isEditMode) ...[
                  Expanded(
                    flex: 1,
                    child: _buildActionButton(
                      text: "삭제",
                      onPressed: () {}, // 삭제 로직 연결
                      isDelete: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    text: isEditMode ? "수정 완료" : "일정 추가하기",
                    onPressed: _onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 공통 피커 박스 위젯
  Widget _buildPickerBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Text(value, style: TextStyle(fontSize: 15.sp)),
      ),
    );
  }

  // 공통 버튼 위젯
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isDelete = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDelete ? Colors.white : NoIllColors.primary,
        foregroundColor: isDelete ? Colors.red : Colors.white,
        elevation: 0,
        side: isDelete ? const BorderSide(color: Colors.red) : BorderSide.none,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
