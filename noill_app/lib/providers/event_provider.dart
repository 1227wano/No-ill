import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_service.dart';
import '../models/event_models.dart';
import '../core/network/dio_provider.dart';

// 1. 서비스 프로바이더 (Dio 주입)
final eventServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return EventService(dio);
});

// 2. 전체 사고 데이터 프로바이더 (서버에서 원본을 긁어옴)
final allEventsProvider = FutureProvider<List<FallEvent>>((ref) async {
  return ref.watch(eventServiceProvider).fetchAccidents();
});

// 3. 🔥 [핵심] 실시간 알람 프로바이더 (24시간 이내 데이터 필터링)
// 기획 의도: 종 모양 아이콘 클릭 시 '사진이 포함된' 최근 알람만 노출
final activeAlarmsProvider = Provider<AsyncValue<List<FallEvent>>>((ref) {
  final allEventsAsync = ref.watch(allEventsProvider);

  return allEventsAsync.whenData((events) {
    final now = DateTime.now();
    // 현재 시간으로부터 24시간이 지나지 않은 이벤트만 선별
    return events.where((event) {
      final difference = now.difference(event.detectedAt).inHours;
      return difference < 24;
    }).toList();
  });
});

// 4. 사고 히스토리 프로바이더 (24시간이 지난 텍스트 위주 데이터)
// 기획 의도: AccidentScreen에서 장기적인 사고 이력을 관리
final accidentHistoryProvider = Provider<AsyncValue<List<FallEvent>>>((ref) {
  final allEventsAsync = ref.watch(allEventsProvider);

  return allEventsAsync.whenData((events) {
    // 최신순으로 정렬하여 반환
    final sortedEvents = [...events];
    sortedEvents.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return sortedEvents;
  });
});
