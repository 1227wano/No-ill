import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../core/network/dio_provider.dart';
import 'care_provider.dart'; // ✅ selectedPetIdProvider를 사용하기 위해 임포트

// 1. 서비스 프로바이더
final scheduleServiceProvider = Provider(
  (ref) => ScheduleService(ref.read(dioProvider)),
);

// 2. 현재 달력에서 선택된 날짜 관리
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 3. 특정 어르신의 전체 일정 데이터를 관리하는 AsyncNotifier
class ScheduleNotifier extends AsyncNotifier<List<ScheduleModel>> {
  @override
  Future<List<ScheduleModel>> build() async {
    // ✅ [수정] 객체가 아닌 String ID만 반환하는 프로바이더를 구독(watch)합니다.
    final petId = ref.watch(selectedPetIdProvider);

    // 어르신이 선택되지 않았다면 빈 목록 반환
    if (petId == null) return [];

    // 서비스 함수에 String 타입의 petId를 전달합니다.
    return await ref.read(scheduleServiceProvider).fetchAllSchedules(petId);
  }

  /// 일정 등록 후 상태 갱신
  Future<void> addSchedule(ScheduleModel schedule) async {
    // ✅ [수정] String ID를 읽어옵니다.
    final petId = ref.read(selectedPetIdProvider);
    if (petId == null) return;

    final success = await ref
        .read(scheduleServiceProvider)
        .createSchedule(schedule, petId);

    if (success) {
      ref.invalidateSelf();
    }
  }

  /// 일정 수정 후 상태 갱신
  Future<void> editSchedule(ScheduleModel schedule) async {
    // ✅ [수정] 일관성을 위해 selectedPetIdProvider 사용
    final petId = ref.read(selectedPetIdProvider);
    if (petId == null) return;

    final success = await ref
        .read(scheduleServiceProvider)
        .updateSchedule(schedule, petId);

    if (success) {
      ref.invalidateSelf();
    }
  }

  /// 일정 삭제 후 상태 갱신
  Future<void> removeSchedule(int id) async {
    final success = await ref.read(scheduleServiceProvider).deleteSchedule(id);
    if (success) {
      ref.invalidateSelf();
    }
  }
}

final scheduleNotifierProvider =
    AsyncNotifierProvider<ScheduleNotifier, List<ScheduleModel>>(() {
      return ScheduleNotifier();
    });

// 4. 선택된 날짜에 해당하는 일정만 필터링 (기존 로직 유지)
final filteredScheduleProvider = Provider<List<ScheduleModel>>((ref) {
  final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
  final selectedDate = ref.watch(selectedDateProvider);

  return allSchedules.where((s) {
    return s.schTime.year == selectedDate.year &&
        s.schTime.month == selectedDate.month &&
        s.schTime.day == selectedDate.day;
  }).toList()..sort((a, b) => a.schTime.compareTo(b.schTime));
});
