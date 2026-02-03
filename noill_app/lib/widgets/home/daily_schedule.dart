// 오늘의 일정 위젯
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class DailyScheduleSection extends StatelessWidget {
  const DailyScheduleSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 데이터 연동 시: final schedules = ref.watch(scheduleProvider); 로 변경
    return Column(
      children: [
        _buildScheduleItem("Evening Check-in", "6:00 PM", true),
        _buildScheduleItem(
          "Morning Medication",
          "8:30 AM",
          false,
          isDone: true,
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    String title,
    String time,
    bool isUrgent, {
    bool isDone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUrgent
                  ? NoIllColors.danger.withOpacity(0.1)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber : Icons.medication,
              color: isUrgent ? NoIllColors.danger : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                isDone ? "Completed at $time" : time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
