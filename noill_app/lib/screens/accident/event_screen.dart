import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/event_provider.dart';

class RecentEventScreen extends ConsumerWidget {
  const RecentEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 실시간 사고 데이터 바구니를 지켜봅니다.
    final recentEvent = ref.watch(recentEventProvider);

    return Scaffold(
      backgroundColor: recentEvent == null
          ? Colors.white
          : const Color(0xFFFFEBEE),
      appBar: AppBar(
        title: const Text(
          "실시간 사고 감지",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: recentEvent == null
            ? _buildSafeState() // 사고가 없을 때 (평상시)
            : _buildEmergencyState(context, ref, recentEvent), // 사고 발생 시
      ),
    );
  }

  // ✅ 1. 평상시 화면 (평화로움)
  Widget _buildSafeState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "현재 감지된 사고가 없습니다.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const Text("시스템이 실시간으로 보호 중입니다.", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  // ✅ 2. 사고 발생 화면 (긴급)
  Widget _buildEmergencyState(
    BuildContext context,
    WidgetRef ref,
    dynamic event,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 긴급 사이렌 아이콘 (깜빡이는 애니메이션 효과를 주면 더 좋습니다)
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),

            // 📸 낚아챈 실시간 사고 현장 이미지
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 사고 설명 박스
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                event.body,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 확인 완료 버튼 (바구니 비우기)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ 확인 버튼을 누르면 바구니를 다시 null로 비웁니다.
                  ref.read(recentEventProvider.notifier).update(null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "상황 확인 완료",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
