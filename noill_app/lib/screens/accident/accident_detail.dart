import 'package:flutter/material.dart';
import '../../models/event_models.dart';

class AccidentDetailScreen extends StatelessWidget {
  final FallEvent event;

  const AccidentDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // ✅ 24시간 경과 여부 판단
    final bool isExpired = now.difference(event.detectedAt).inHours >= 24;

    return Scaffold(
      appBar: AppBar(title: const Text("사고 상세 기록"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상태 배지 및 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(isExpired),
                Text(
                  "${event.detectedAt.year}.${event.detectedAt.month}.${event.detectedAt.day} ${event.detectedAt.hour}:${event.detectedAt.minute}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 고정된 제목 및 내용
            Text(
              event.title, // "낙상 사고 감지"
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),

            // 3. 사진 영역 (실시간 알림 시에만 노출)
            // ✅ 과거 기록(isExpired)이거나 이미지 주소가 없으면 영역 자체를 숨김
            if (!isExpired &&
                event.imageUrl != null &&
                event.imageUrl!.isNotEmpty) ...[
              const Text(
                "사고 현장 기록",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  event.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text("사진을 불러올 수 없습니다.")),
                ),
              ),
            ],

            const SizedBox(height: 40),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("보고서 안내"),
              subtitle: Text("해당 기록은 낙상 감지 센서에 의해 자동 생성되었습니다."),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey[200] : const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isExpired ? "기록 보존됨" : "실시간 감지",
        style: TextStyle(
          color: isExpired ? Colors.grey[600] : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
