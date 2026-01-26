// 주간 일정 확인
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/schedule/schedule_form_modal.dart';
import '../../core/constants/color_constants.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoIllColors.background,
      appBar: AppBar(
        title: const Text(
          "일정 관리",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // 키보드 가림 방지
                backgroundColor: Colors.transparent,
                builder: (context) => const ScheduleFormModal(),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: NoIllColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 주간 날짜 선택 바 (Mock)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 7,
              itemBuilder: (context, index) {
                bool isToday = index == 2; // 오늘 날짜 표시 예시
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isToday ? NoIllColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "월",
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.grey,
                        ),
                      ),
                      Text(
                        "${20 + index}",
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 2. 상세 일정 리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              children: [
                _buildTimeSlot(
                  "08:00 AM",
                  "아침 식사 및 투약",
                  Icons.restaurant,
                  Colors.orange,
                ),
                _buildTimeSlot(
                  "10:30 AM",
                  "동네 산책",
                  Icons.directions_walk,
                  Colors.blue,
                ),
                _buildTimeSlot(
                  "01:00 PM",
                  "점심 식사",
                  Icons.flatware,
                  Colors.green,
                ),
                _buildTimeSlot(
                  "06:00 PM",
                  "저녁 정기 확인",
                  Icons.notification_important,
                  NoIllColors.danger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 20),
          Container(height: 30, width: 2, color: color.withOpacity(0.3)),
          const SizedBox(width: 20),
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
    );
  }
}
