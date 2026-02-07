import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noill_app/screens/schedule/schedule_form_sheet.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/schedule_model.dart';
import '../../providers/schedule_provider.dart';

// 💡 보기 모드 관리를 위한 프로바이더 (추가)
final calendarExpandedProvider = StateProvider<bool>((ref) => true);

class ScheduleMainScreen extends ConsumerWidget {
  const ScheduleMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailySchedules = ref.watch(filteredScheduleProvider);
    final scheduleAsync = ref.watch(scheduleNotifierProvider);
    final isExpanded = ref.watch(calendarExpandedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("어르신 일정 관리"),
        centerTitle: false, // 아이콘 배치를 위해 왼쪽 정렬 권장
        actions: [
          // 1. 등록 아이콘
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showAddScheduleSheet(context),
          ),
          // 2. 월별/일별 보기 전환 (달력 접기/펴기)
          IconButton(
            icon: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.calendar_month,
            ),
            onPressed: () =>
                ref.read(calendarExpandedProvider.notifier).state = !isExpanded,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 상단: 월간 캘린더 (토글 가능) ---
          if (isExpanded)
            _buildCalendar(ref, selectedDate, scheduleAsync.value ?? []),

          const Divider(thickness: 1, height: 1),

          // --- 하단: 일별 타임라인 리스트 ---
          Expanded(
            child: dailySchedules.isEmpty
                ? _buildEmptyState()
                : _buildTimelineList(dailySchedules, ref),
          ),
        ],
      ),
    );
  }

  // 캘린더 위젯
  Widget _buildCalendar(
    WidgetRef ref,
    DateTime selectedDate,
    List<ScheduleModel> allSchedules,
  ) {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDate,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        // ✅ 선택 날짜 업데이트 (Provider 연동)
        ref.read(selectedDateProvider.notifier).update(selectedDay);
      },
      // 이벤트가 있는 날짜에 점 표시
      eventLoader: (day) {
        return allSchedules.where((s) => isSameDay(s.schTime, day)).toList();
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.deepOrange,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  // 타임라인 리스트
  Widget _buildTimelineList(List<ScheduleModel> schedules, WidgetRef ref) {
    return ListView.builder(
      // 💡 하단바 높이만큼 여백을 주어 마지막 아이템이 가려지지 않게 합니다.
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final bool isPassed = schedule.isPassed; // ✅ 시간 지남 여부 판단

        return ListTile(
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${schedule.schTime.hour.toString().padLeft(2, '0')}:${schedule.schTime.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.grey : Colors.black, // ✅ 회색 처리 로직
                ),
              ),
              if (isPassed)
                const Icon(Icons.check_circle, size: 16, color: Colors.grey),
            ],
          ),
          title: Text(
            schedule.schName,
            style: TextStyle(
              decoration: isPassed
                  ? TextDecoration.lineThrough
                  : null, // ✅ 취소선 추가
              color: isPassed ? Colors.grey : Colors.black87,
              fontWeight: isPassed ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: schedule.schMemo != null ? Text(schedule.schMemo!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditScheduleSheet(context, schedule),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "기록된 일정이 없습니다.\n새로운 일정을 추가해 보세요!",
        textAlign: TextAlign.center,
      ),
    );
  }

  // 등록 아이콘 눌렀을 때
  void _showAddScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 대응을 위해 필수
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ScheduleFormSheet(),
    );
  }

  // 리스트 아이템의 수정 버튼 눌렀을 때
  void _showEditScheduleSheet(BuildContext context, ScheduleModel schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ScheduleFormSheet(schedule: schedule), // 기존 데이터 전달
    );
  }
}
