import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noill_app/core/constants/color_constants.dart';
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
                ? _buildEmptyState(ref)
                : _buildTimelineList(dailySchedules, ref),
          ),
        ],
      ),
    );
  }

  // 캘린더 위젯
  // 캘린더 위젯: 점 제거 + 오늘(브랜드색) + 선택(회색)
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
        // ✅ 선택한 날짜를 상태에 저장
        ref.read(selectedDateProvider.notifier).update(selectedDay);
      },

      // 1. 달력의 점(마커)을 데이터 단계에서 제거합니다.
      eventLoader: (day) => [],

      calendarStyle: CalendarStyle(
        // 2. 오늘 날짜: 노일 브랜드 컬러(0xFF6A85B6) 적용
        todayDecoration: const BoxDecoration(
          color: NoIllColors.primary,
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),

        // 3. 선택한 날짜: 회색(Colors.grey)으로 처리
        selectedDecoration: const BoxDecoration(
          color: Color.fromARGB(255, 186, 186, 186),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),

        // 기타 UI 정리
        outsideDaysVisible: false, // 다른 달 날짜 숨기기
        weekendTextStyle: const TextStyle(color: Colors.redAccent),
      ),

      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 타임라인 리스트
  Widget _buildTimelineList(List<ScheduleModel> schedules, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(scheduleNotifierProvider);
        return await ref.watch(scheduleNotifierProvider.future);
      },
      child: ListView.builder(
        // 일정이 적어도 당겨서 새로고침 가능하게 함
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    // ref 추가
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(scheduleNotifierProvider);
        return await ref.watch(scheduleNotifierProvider.future);
      },
      child: SingleChildScrollView(
        // ✅ 화면 전체 높이를 차지하게 해서 어디서든 당길 수 있게 함
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 400, // 적당한 높이 부여 (혹은 LayoutBuilder로 유연하게 조정)
          alignment: Alignment.center,
          child: const Text(
            "기록된 일정이 없습니다.\n새로운 일정을 추가해 보세요!",
            textAlign: TextAlign.center,
          ),
        ),
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
