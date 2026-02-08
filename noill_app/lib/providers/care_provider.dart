// lib/providers/care_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import 'auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// Service Provider
// ═══════════════════════════════════════════════════════════════════════

final petServiceProvider = Provider<PetService>((ref) {
  final dio = ref.watch(dioProvider);
  return PetService(dio);
});

// ═══════════════════════════════════════════════════════════════════════
// Care List Notifier - 어르신 목록 관리
// ═══════════════════════════════════════════════════════════════════════

class CareListNotifier extends AsyncNotifier<List<PetModel>> {
  final _logger = AppLogger('CareListNotifier');

  @override
  Future<List<PetModel>> build() async {
    // 인증 상태 확인
    final authStatus = ref.watch(authProvider.select((s) => s.status));

    if (authStatus != AuthStatus.authenticated) {
      _logger.info('미인증 상태 - 빈 리스트 반환');
      return [];
    }

    // 어르신 목록 로드
    return await _loadCareList();
  }

  /// 어르신 목록 로드
  Future<List<PetModel>> _loadCareList() async {
    try {
      _logger.info('어르신 목록 로드 시작');

      final service = ref.read(petServiceProvider);
      final result = await service.fetchMyPets();

      return result.fold(
        onSuccess: (pets) {
          _logger.info('어르신 목록 ${pets.length}명 로드 완료');

          // 첫 번째 어르신 자동 선택 (목록이 비어있지 않고, 선택된 어르신이 없을 때)
          if (pets.isNotEmpty && ref.read(selectedPetProvider) == null) {
            _logger.info('첫 번째 어르신 자동 선택: ${pets.first.petName}');
            ref.read(selectedPetProvider.notifier).update(pets.first);
          }

          return pets;
        },
        onFailure: (exception) {
          _logger.error('어르신 목록 로드 실패: ${exception.message}');
          throw exception;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      rethrow;
    }
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    _logger.info('어르신 목록 새로고침');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCareList());
  }

  /// 어르신 추가 (UI 즉시 반영)
  void addPet(PetModel newPet) {
    _logger.info('어르신 추가: ${newPet.petName} (${newPet.petId})');

    state.whenData((currentList) {
      // 중복 확인
      if (currentList.any((p) => p.petId == newPet.petId)) {
        _logger.warning('이미 존재하는 어르신: ${newPet.petId}');
        return;
      }

      // 목록에 추가
      final updatedList = [...currentList, newPet];
      state = AsyncData(updatedList);
      _logger.info('어르신 목록 업데이트 완료: ${updatedList.length}명');

      // 자동 선택 (첫 번째 등록이거나 선택된 어르신이 없을 때)
      if (currentList.isEmpty || ref.read(selectedPetProvider) == null) {
        _logger.info('새 어르신 자동 선택: ${newPet.petName}');
        ref.read(selectedPetProvider.notifier).update(newPet);
      }
    });
  }

  /// 어르신 제거
  void removePet(String petId) {
    _logger.info('어르신 제거: $petId');

    state.whenData((currentList) {
      final updatedList = currentList.where((p) => p.petId != petId).toList();
      state = AsyncData(updatedList);
      _logger.info('어르신 목록 업데이트 완료: ${updatedList.length}명');

      // 선택된 어르신이 제거된 경우 선택 해제
      final selectedPet = ref.read(selectedPetProvider);
      if (selectedPet?.petId == petId) {
        _logger.info('제거된 어르신이 선택되어 있음 - 선택 해제');
        ref.read(selectedPetProvider.notifier).update(
            updatedList.isNotEmpty ? updatedList.first : null);
      }
    });
  }

  /// 어르신 정보 업데이트
  void updatePet(PetModel updatedPet) {
    _logger.info('어르신 정보 업데이트: ${updatedPet.petName}');

    state.whenData((currentList) {
      final updatedList = currentList.map((p) {
        return p.petId == updatedPet.petId ? updatedPet : p;
      }).toList();

      state = AsyncData(updatedList);
      _logger.info('어르신 목록 업데이트 완료');

      // 선택된 어르신도 업데이트
      final selectedPet = ref.read(selectedPetProvider);
      if (selectedPet?.petId == updatedPet.petId) {
        _logger.info('선택된 어르신 정보도 업데이트');
        ref.read(selectedPetProvider.notifier).update(updatedPet);
      }
    });
  }

  /// 어르신 등록 (통합 메서드)
  Future<bool> registerPetAndSenior({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      _logger.info('어르신 등록 시작: $petName ($petId)');

      final service = ref.read(petServiceProvider);
      final result = await service.registerCare(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      return result.fold(
        onSuccess: (newPet) {
          _logger.info('어르신 등록 성공: ${newPet.petName}');

          // 목록에 추가
          addPet(newPet);

          // 자동 선택
          ref.read(selectedPetProvider.notifier).update(newPet);

          return true;
        },
        onFailure: (exception) {
          _logger.error('어르신 등록 실패: ${exception.message}');
          return false;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 등록 에러', e, stackTrace);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════

/// 어르신 목록 Provider
final careListProvider = AsyncNotifierProvider<CareListNotifier, List<PetModel>>(
      () => CareListNotifier(),
);

/// 현재 선택된 어르신 (Single Source of Truth)
class SelectedPetNotifier extends Notifier<PetModel?> {
  @override
  PetModel? build() => null;

  void update(PetModel? value) {
    state = value;
  }
}

final selectedPetProvider = NotifierProvider<SelectedPetNotifier, PetModel?>(
  () => SelectedPetNotifier(),
);

/// 선택된 어르신 ID
final selectedPetIdProvider = Provider<String?>((ref) {
  return ref.watch(selectedPetProvider)?.petId;
});

/// 선택된 어르신 번호 (서버 DB용)
final selectedPetNoProvider = Provider<int?>((ref) {
  return ref.watch(selectedPetProvider)?.petNo;
});

/// 선택된 어르신 이름
final selectedPetNameProvider = Provider<String?>((ref) {
  return ref.watch(selectedPetProvider)?.petName;
});

/// 선택된 어르신 돌봄 대상자 이름
final selectedCareNameProvider = Provider<String?>((ref) {
  return ref.watch(selectedPetProvider)?.careName;
});

/// 어르신 선택 여부
final hasPetSelectedProvider = Provider<bool>((ref) {
  return ref.watch(selectedPetProvider) != null;
});

/// 어르신 목록이 비어있는지 확인
final isPetListEmptyProvider = Provider<bool>((ref) {
  final asyncList = ref.watch(careListProvider);
  return asyncList.value?.isEmpty ?? true;
});
