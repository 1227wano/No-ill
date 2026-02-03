// 홈 화면 상단 사고 알림 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fcm_service.dart';

class LatestAccidentBanner extends ConsumerWidget {
  const LatestAccidentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 최신 이미지 URL 상태 감시
    final imageUrl = ref.watch(latestAccidentImageProvider);

    // 사고 데이터가 없으면 표시 안 함
    if (imageUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.report_problem, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  "긴급! 낙상 사고 감지",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () =>
                      ref.read(latestAccidentImageProvider.notifier).state =
                          null,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Text("이미지를 불러올 수 없습니다.")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
