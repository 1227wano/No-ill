import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // 시간 포맷팅을 위해 필요 (flutter pub add intl)
import '../../providers/schedule_provider.dart';

class DailyScheduleSection extends ConsumerWidget {
  const DailyScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 오늘 날짜로 필터링된 일정 리스트 구독
    final schedules = ref.watch(filteredScheduleProvider);

    // 2. 전체 일정 로딩 상태 확인 (AsyncNotifier 감시)
    final scheduleAsync = ref.watch(scheduleNotifierProvider);

    return scheduleAsync.when(
      data: (_) {
        if (schedules.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text("오늘 예정된 일정이 없습니다."),
            ),
          );
        }

        return Column(
          children: schedules.map((item) {
            // schTime(DateTime)을 읽기 좋은 시간으로 변환
            final String timeStr = DateFormat('h:mm a').format(item.schTime);

            return _buildScheduleItem(
              item.schName, // 1. 제목 (schName)
              timeStr, // 2. 시간
              isDone: item.schStatus == "DONE", // 🎯 상태가 "DONE"이면 취소선 표시
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text("일정을 불러오는 중 오류가 발생했습니다.")),
    );
  }

  Widget _buildScheduleItem(String title, String time, {bool isDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone ? "완료됨 ($time)" : time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
