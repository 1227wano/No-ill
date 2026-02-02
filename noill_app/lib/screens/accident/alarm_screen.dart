import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ✅ 시간 포맷팅을 위해 추가

import '../../providers/event_provider.dart'; // 데이터 소스
import 'accident_detail.dart'; // 상세 화면 연결

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 24시간 이내의 활성 알람만 가져오는 Provider 구독
    final alarmsAsync = ref.watch(activeAlarmsProvider); // 곧 생길 GET 요청
    final liveAlarms = ref.watch(liveNotificationProvider); // 앱 실행 중 받은 실시간 데이터

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "실시간 알림 (24시간)",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: alarmsAsync.when(
        data: (serverAlarms) {
          // 1. 모든 리스트를 하나로 합침
          final combined = [...liveAlarms, ...serverAlarms];

          // 2. 중복 제거 (eventId가 같으면 하나만 남김)
          final uniqueAlarms = {
            for (var item in combined) item.eventNo: item,
          }.values.toList();

          // 3. 최신순 정렬 (detectedAt 기준 내림차순)
          uniqueAlarms.sort((a, b) => b.eventTime.compareTo(a.eventTime));

          return ListView.builder(
            itemCount: uniqueAlarms.length,
            itemBuilder: (context, index) =>
                _buildAlarmCard(context, uniqueAlarms[index]),
          );
        },
        // API가 아직 없어 에러가 나더라도 실시간 데이터는 보여줍니다.
        error: (err, stack) => liveAlarms.isNotEmpty
            ? _buildAlarmList(liveAlarms)
            : _buildErrorState(err.toString()),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // --- 위젯 분리: 알람 리스트 ---
  Widget _buildAlarmList(List<dynamic> alarms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alarms.length,
      itemBuilder: (context, index) => _buildAlarmCard(context, alarms[index]),
    );
  }

  // --- 위젯 분리: 에러 상태 ---
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "서버 연결 대기 중...\n실시간 알림이 오면 여기에 표시됩니다.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  // 1. 알람이 없을 때 보여줄 화면
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "현재 활성화된 알림이 없습니다.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 2. 개별 알람 카드 위젯 (사진 + 텍스트)
  Widget _buildAlarmCard(BuildContext context, dynamic alarm) {
    // 💡 DATETIME 포맷팅: "오후 02:05" 형식
    final String formattedTime = DateFormat(
      'aa hh:mm',
      'ko_KR',
    ).format(alarm.detectedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // 🚨 클릭 시 상세 화면(FallDetailScreen)으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccidentDetailScreen(event: alarm),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사고 사진 영역 (24시간만 유효)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                alarm.imageUrl,
                fit: BoxFit.cover,
                // loadingBuilder: (context, child, loadingProgress) {
                //   if (loadingProgress == null) return child;
                //   return const Center(child: CircularProgressIndicator());
                // },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text("이미지를 불러올 수 없습니다.")),
                ),
              ),
            ),
            // 정보 텍스트 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "⚠️ 낙상 감지",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${alarm.detectedAt.hour}시 ${alarm.detectedAt.minute}분",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alarm.description, // 예: "거실에서 어르신의 낙상이 감지되었습니다."
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
