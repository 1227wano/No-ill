import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class AccidentHistoryScreen extends StatelessWidget {
  const AccidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoIllColors.background, // Milky Ivory 배경
      appBar: AppBar(
        title: const Text(
          "사고 기록 기록",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          _buildHistoryItem(
            context,
            title: "낙상 의심 감지",
            date: "2026.01.25 14:20",
            desc: "거실에서 큰 충격음과 함께 어르신의 위치 변화가 감지되지 않아 긴급 알림을 전송했습니다.",
            statusColor: Colors.red,
            icon: Icons.warning_rounded,
          ),
          _buildHistoryItem(
            context,
            title: "장시간 부동 상태",
            date: "2026.01.22 09:15",
            desc: "침실에서 4시간 이상 움직임이 감지되지 않았습니다. 로봇이 현장으로 이동하여 상태를 확인했습니다.",
            statusColor: Colors.orange,
            icon: Icons.info_outline,
          ),
          _buildHistoryItem(
            context,
            title: "정기 순찰 보고",
            date: "2026.01.20 18:00",
            desc: "오후 정기 순찰 결과, 집안 환경 및 어르신의 상태가 모두 '안전'함으로 확인되었습니다.",
            statusColor: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  // 사고 기록 카드 위젯
  Widget _buildHistoryItem(
    BuildContext context, {
    required String title,
    required String date,
    required String desc,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // 둥근 모서리 적용
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 상태 인디케이터 (점)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Divider(height: 32, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 상세 보기 텍스트 버튼 느낌
              Text(
                "상세 리포트 보기",
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
