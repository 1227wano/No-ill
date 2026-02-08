// lib/providers/event_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../core/network/dio_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import 'care_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════

final eventServiceProvider = Provider<EventService>((ref) {
  final dio = ref.read(dioProvider);
  return EventService(dio);
});

/// 실시간 푸시 알림으로 수신된 최근 사고 (FCM에서 업데이트)
class RecentEventNotifier extends Notifier<EventModel?> {
  @override
  EventModel? build() => null;

  void update(EventModel? value) {
    state = value;
  }
}

final recentEventProvider = NotifierProvider<RecentEventNotifier, EventModel?>(
  () => RecentEventNotifier(),
);

/// 특정 어르신의 사고 기록 목록 (petId로 조회)
final eventListByPetProvider = FutureProvider.family<List<EventModel>, String>(
      (ref, petId) async {
    final logger = AppLogger('eventListByPetProvider');
    logger.info('사고 기록 조회: $petId');

    final eventService = ref.read(eventServiceProvider);
    final result = await eventService.fetchEvents(petId);

    return result.fold(
      onSuccess: (events) {
        // 최신순 정렬
        events.sort((a, b) => b.eventTime.compareTo(a.eventTime));
        logger.info('사고 기록 ${events.length}건 로드 완료 (정렬됨)');
        return events;
      },
      onFailure: (exception) {
        logger.error('사고 기록 로드 실패: ${exception.message}');
        throw exception;
      },
    );
  },
);

/// 현재 선택된 어르신의 사고 기록 목록
final selectedPetEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final logger = AppLogger('selectedPetEventsProvider');

  // 선택된 어르신 확인
  final selectedPet = ref.watch(selectedPetProvider);
  if (selectedPet == null) {
    logger.info('선택된 어르신 없음 - 빈 리스트 반환');
    return [];
  }

  // 해당 어르신의 사고 기록 조회
  return ref.watch(eventListByPetProvider(selectedPet.petId).future);
});

/// 최근 사고 기록 (최대 5개)
final recentEventsProvider = Provider<List<EventModel>>((ref) {
  final events = ref.watch(selectedPetEventsProvider).value ?? [];
  return events.take(5).toList();
});

/// 특정 날짜의 사고 기록 필터링
final eventsByDateProvider = Provider.family<List<EventModel>, DateTime>(
      (ref, date) {
    final events = ref.watch(selectedPetEventsProvider).value ?? [];

    return events.where((event) {
      return event.eventTime.year == date.year &&
          event.eventTime.month == date.month &&
          event.eventTime.day == date.day;
    }).toList();
  },
);

/// 사고 통계
final eventStatsProvider = Provider<EventStats>((ref) {
  final events = ref.watch(selectedPetEventsProvider).value ?? [];

  return EventStats(
    totalCount: events.length,
    todayCount: events.where((e) => _isToday(e.eventTime)).length,
    weekCount: events.where((e) => _isThisWeek(e.eventTime)).length,
    monthCount: events.where((e) => _isThisMonth(e.eventTime)).length,
  );
});

/// 가장 최근 사고 (푸시 알림 or 목록의 첫 번째)
final latestEventProvider = Provider<EventModel?>((ref) {
  // 1순위: 실시간 푸시로 받은 사고
  final recentEvent = ref.watch(recentEventProvider);
  if (recentEvent != null) return recentEvent;

  // 2순위: 목록의 가장 최근 사고
  final events = ref.watch(selectedPetEventsProvider).value ?? [];
  return events.isNotEmpty ? events.first : null;
});

// ═══════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool _isThisWeek(DateTime date) {
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  return date.isAfter(weekAgo);
}

bool _isThisMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

// ═══════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════

class EventStats {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  final int monthCount;

  const EventStats({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
  });

  @override
  String toString() {
    return 'EventStats(total: $totalCount, today: $todayCount, week: $weekCount, month: $monthCount)';
  }
}
