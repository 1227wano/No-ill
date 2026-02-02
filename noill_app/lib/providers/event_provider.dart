import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/network/dio_provider.dart';
import '../models/event_models.dart';
import '../services/event_service.dart';
import './care_provider.dart'; // 💡 [추가] 선택된 어르신 ID를 가져오기 위해 필요

// 1. 서비스 프로바이더 (Dio 주입)
final eventServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return EventService(dio);
});

// ✅ 실시간 푸시 알림 데이터를 임시 저장하는 리스트 프로바이더
final liveNotificationProvider = StateProvider<List<FallEvent>>((ref) => []);

// 2. 전체 사고 데이터 프로바이더 (서버에서 원본을 긁어옴)
final allEventsProvider = FutureProvider<List<FallEvent>>((ref) async {
  // ① 현재 드롭다운에서 선택된 어르신의 ID를 관찰합니다.
  final selectedId = ref.watch(selectedPetIdProvider);

  if (selectedId == null) return [];

  // ② 서버에서 전체 사고 리스트를 긁어옵니다.
  final allEvents = await ref.read(eventServiceProvider).fetchAccidentsReal();

  // ③ [필터링] 가져온 데이터 중, 현재 선택된 어르신의 ID와 일치하는 기록만 골라냅니다.
  // 💡 모델(FallEvent)에 petId 필드가 반드시 정의되어 있어야 합니다.
  return allEvents.where((event) => event.petNo == selectedId).toList();
});

// 3. 🔥 [핵심] 실시간 알람 프로바이더 (24시간 이내 데이터 필터링)
// 기획 의도: 종 모양 아이콘 클릭 시 '사진이 포함된' 최근 알람만 노출
final activeAlarmsProvider = Provider<AsyncValue<List<FallEvent>>>((ref) {
  final allEventsAsync = ref.watch(allEventsProvider);

  return allEventsAsync.whenData((events) {
    final now = DateTime.now();
    // 현재 시간으로부터 24시간이 지나지 않은 이벤트만 선별
    return events.where((event) {
      final difference = now.difference(event.eventTime).inHours;
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
    sortedEvents.sort((a, b) => b.eventTime.compareTo(a.eventTime));
    return sortedEvents;
  });
});
