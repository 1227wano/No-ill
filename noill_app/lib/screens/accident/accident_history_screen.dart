import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 추가
import '../../core/constants/color_constants.dart';
import '../../providers/event_provider.dart'; // 추가
import 'accident_detail.dart'; // 상세 화면 이동을 위해 추가

class AccidentHistoryScreen extends ConsumerWidget {
  // StatelessWidget -> ConsumerWidget 변경
  const AccidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 1. 전체 사고 이력 프로바이더 구독
    final historyAsync = ref.watch(accidentHistoryProvider);

    return Scaffold(
      backgroundColor: NoIllColors.background,
      appBar: AppBar(
        title: const Text(
          "사고 기록",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // ✅ 2. 데이터 상태(로딩/성공/에러)에 따른 처리
      body: historyAsync.when(
        data: (events) => events.isEmpty
            ? const Center(child: Text("기록된 사고가 없습니다."))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildHistoryItem(
                    context,
                    event: event, // 모델을 통째로 넘김
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("데이터 로드 실패: $err")),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, {required dynamic event}) {
    // 24시간 이내면 빨간색, 아니면 회색으로 표시하는 로직 추가 가능
    final isRecent = DateTime.now().difference(event.detectedAt).inHours < 24;

    return InkWell(
      // ✅ 클릭 시 상세 화면으로 이동
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentDetailScreen(event: event),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isRecent ? Colors.red : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  event.title,
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
              event.description,
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
                  "${event.detectedAt.year}.${event.detectedAt.month}.${event.detectedAt.day}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "상세 리포트 보기",
                  style: TextStyle(
                    color: isRecent ? Colors.red : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
