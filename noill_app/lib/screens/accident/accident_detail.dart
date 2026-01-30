import 'package:flutter/material.dart';
import '../../models/event_models.dart'; //

class AccidentDetailScreen extends StatelessWidget {
  final FallEvent event; // 모델을 통째로 넘겨받아 사용

  const AccidentDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 💡 24시간 경과 여부 판단
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

            // 2. 제목 및 상세 내용
            Text(
              event.title,
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

            // 3. 사진 영역 (24시간 정책 반영)
            const Text(
              "사고 현장 기록",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildImageArea(isExpired),

            const SizedBox(height: 40),

            // 4. 기록용 메모 또는 관리 액션
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("보고서 관리"),
              subtitle: const Text("이 사고 기록은 서버에 영구 보관됩니다."),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 추가 기능 연결 가능
              },
            ),
          ],
        ),
      ),
    );
  }

  // 상단 상태 배지 (최근/과거 구분)
  Widget _buildStatusBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey[200] : const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isExpired ? "기록 보관됨" : "최근 사고",
        style: TextStyle(
          color: isExpired ? Colors.grey[600] : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 이미지 영역: 24시간이 지나면 안내 문구 노출
  Widget _buildImageArea(bool isExpired) {
    if (isExpired) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text(
              "보안 정책에 따라 24시간이 경과한\n현장 사진은 파기되었습니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          event.imageUrl, //
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text("사진을 불러올 수 없습니다.")),
        ),
      );
    }
  }
}
