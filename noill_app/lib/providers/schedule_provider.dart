// lib/providers/schedule_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../core/network/dio_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import 'care_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// Service Provider
// ═══════════════════════════════════════════════════════════════════════

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final dio = ref.read(dioProvider);
  return ScheduleService(dio);
});

// ═══════════════════════════════════════════════════════════════════════
// State Providers
// ═══════════════════════════════════════════════════════════════════════

/// 현재 선택된 날짜
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void update(DateTime value) {
    state = value;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  () => SelectedDateNotifier(),
);

/// 현재 선택된 월 (달력용)
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void update(DateTime value) {
    state = value;
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  () => SelectedMonthNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════
// Schedule Notifier - 일정 관리
// ═══════════════════════════════════════════════════════════════════════

class ScheduleNotifier extends AsyncNotifier<List<ScheduleModel>> {
  final _logger = AppLogger('ScheduleNotifier');

  @override
  Future<List<ScheduleModel>> build() async {
    // 선택된 어르신 ID 확인
    final petId = ref.watch(selectedPetIdProvider);

    if (petId == null) {
      _logger.info('선택된 어르신 없음 - 빈 리스트 반환');
      return [];
    }

    // 전체 일정 로드
    return await _loadAllSchedules(petId);
  }

  /// 전체 일정 로드
  Future<List<ScheduleModel>> _loadAllSchedules(String petId) async {
    try {
      _logger.info('전체 일정 로드: $petId');

      final service = ref.read(scheduleServiceProvider);
      final result = await service.fetchAllSchedules(petId);

      return result.fold(
        onSuccess: (schedules) {
          _logger.info('일정 ${schedules.length}개 로드 완료');
          return schedules;
        },
        onFailure: (exception) {
          _logger.error('일정 로드 실패: ${exception.message}');
          throw exception;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      rethrow;
    }
  }

  /// 일정 추가
  Future<bool> addSchedule(ScheduleModel schedule, String petId) async {
    try {
      _logger.info('일정 추가: ${schedule.schName}');

      final service = ref.read(scheduleServiceProvider);
      final result = await service.createSchedule(schedule, petId);

      return result.fold(
        onSuccess: (createdSchedule) {
          _logger.info('일정 추가 성공: ${createdSchedule.schName}');

          // 목록 새로고침
          ref.invalidateSelf();
          return true;
        },
        onFailure: (exception) {
          _logger.error('일정 추가 실패: ${exception.message}');
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return false;
    }
  }

  /// 일정 수정
  Future<bool> editSchedule(ScheduleModel schedule, String petId) async {
    try {
      _logger.info('일정 수정: ID=${schedule.id}, ${schedule.schName}');

      final service = ref.read(scheduleServiceProvider);
      final result = await service.updateSchedule(schedule, petId);

      return result.fold(
        onSuccess: (updatedSchedule) {
          _logger.info('일정 수정 성공: ${updatedSchedule.schName}');

          // 목록 새로고침
          ref.invalidateSelf();
          return true;
        },
        onFailure: (exception) {
          _logger.error('일정 수정 실패: ${exception.message}');
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return false;
    }
  }

  /// 일정 삭제
  Future<bool> removeSchedule(int id) async {
    try {
      _logger.info('일정 삭제: ID=$id');

      // 선택된 어르신 ID 확인
      final petId = ref.read(selectedPetIdProvider);
      if (petId == null) {
        _logger.error('선택된 어르신 없음 - 삭제 중단');
        return false;
      }

      final service = ref.read(scheduleServiceProvider);
      final result = await service.deleteSchedule(id, petId);

      return result.fold(
        onSuccess: (_) {
          _logger.info('일정 삭제 성공');

          // 목록 새로고침
          ref.invalidateSelf();
          return true;
        },
        onFailure: (exception) {
          _logger.error('일정 삭제 실패: ${exception.message}');
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return false;
    }
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    _logger.info('일정 목록 새로고침');
    ref.invalidateSelf();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════

/// 전체 일정 목록
final scheduleNotifierProvider =
    AsyncNotifierProvider<ScheduleNotifier, List<ScheduleModel>>(
      () => ScheduleNotifier(),
    );

/// 선택된 날짜의 일정만 필터링
final filteredScheduleProvider = Provider<List<ScheduleModel>>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final selectedDate = ref.watch(selectedDateProvider);

  return allSchedules
      .where((schedule) => _isSameDay(schedule.schTime, selectedDate))
      .toList()
    ..sort((a, b) => a.schTime.compareTo(b.schTime));
});

/// 선택된 월의 일정만 필터링
final monthlyScheduleProvider = Provider<List<ScheduleModel>>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);

  return allSchedules
      .where((schedule) => _isSameMonth(schedule.schTime, selectedMonth))
      .toList()
    ..sort((a, b) => a.schTime.compareTo(b.schTime));
});

/// 오늘의 일정
final todayScheduleProvider = Provider<List<ScheduleModel>>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final today = DateTime.now();

  return allSchedules
      .where((schedule) => _isSameDay(schedule.schTime, today))
      .toList()
    ..sort((a, b) => a.schTime.compareTo(b.schTime));
});

/// 다가오는 일정 (미래 일정만, 최대 10개)
final upcomingScheduleProvider = Provider<List<ScheduleModel>>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final now = DateTime.now();

  return allSchedules
      .where((schedule) => schedule.schTime.isAfter(now))
      .toList()
    ..sort((a, b) => a.schTime.compareTo(b.schTime))
    ..take(10);
});

/// 특정 날짜에 일정이 있는지 확인 (달력 마커용)
final hasScheduleOnDateProvider = Provider.family<bool, DateTime>((ref, date) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  return allSchedules.any((schedule) => _isSameDay(schedule.schTime, date));
});

/// 일정 통계
final scheduleStatsProvider = Provider<ScheduleStats>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final now = DateTime.now();

  return ScheduleStats(
    totalCount: allSchedules.length,
    todayCount: allSchedules.where((s) => _isSameDay(s.schTime, now)).length,
    weekCount: allSchedules.where((s) => _isThisWeek(s.schTime)).length,
    monthCount: allSchedules.where((s) => _isSameMonth(s.schTime, now)).length,
    upcomingCount: allSchedules.where((s) => s.schTime.isAfter(now)).length,
    pastCount: allSchedules.where((s) => s.schTime.isBefore(now)).length,
  );
});

// ═══════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

bool _isThisWeek(DateTime date) {
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  return date.isAfter(weekAgo) &&
      date.isBefore(now.add(const Duration(days: 1)));
}

// ═══════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════

class ScheduleStats {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final int upcomingCount;
  final int pastCount;

  const ScheduleStats({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.upcomingCount,
    required this.pastCount,
  });

  @override
  String toString() {
    return 'ScheduleStats(total: $totalCount, today: $todayCount, week: $weekCount, month: $monthCount)';
  }
}
