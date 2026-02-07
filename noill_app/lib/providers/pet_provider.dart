// lib/providers/pet_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_model.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import 'care_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// petServiceProvider는 care_provider.dart에서 정의됨
// ═══════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════
// 2. Pet Registration Notifier (어르신 등록 상태 관리)
// ═══════════════════════════════════════════════════════════════════════

/// 어르신 등록 과정의 상태를 관리하는 Notifier
///
/// 사용 흐름:
/// 1. updatePetId() - 기기 ID 입력
/// 2. updatePetName() - 어르신 이름 입력
/// 3. updateProfile() - 주소, 전화번호, 돌봄 대상자 이름 입력
/// 4. submit() - 서버에 등록 요청
class PetRegistrationNotifier extends Notifier<PetModel> {
  final _logger = AppLogger('PetRegistrationNotifier');

  @override
  PetModel build() {
    return PetModel(petId: '');
  }

  /// 기기 ID 업데이트
  void updatePetId(String id) {
    _logger.debug('기기 ID 업데이트: $id');
    state = state.copyWith(petId: id);
  }

  /// 어르신 이름 업데이트
  void updatePetName(String name) {
    _logger.debug('어르신 이름 업데이트: $name');
    state = state.copyWith(petName: name);
  }

  /// 프로필 정보 업데이트 (주소, 전화번호, 돌봄 대상자 이름)
  void updateProfile({
    required String address,
    required String phone,
    required String careName,
  }) {
    _logger.debug('프로필 업데이트: $careName, $address, $phone');
    state = state.copyWith(
      petAddress: address,
      petPhone: phone,
      careName: careName,
    );
  }

  /// 전체 상태 초기화
  void reset() {
    _logger.info('등록 상태 초기화');
    state = PetModel(petId: '');
  }

  /// 서버에 등록 요청
  ///
  /// Returns: true - 등록 성공
  ///          false - 등록 실패
  Future<bool> submit() async {
    try {
      _logger.info('어르신 등록 제출 시작: ${state.petName} (${state.petId})');

      // 입력값 검증
      if (!_validateState()) {
        return false;
      }

      final service = ref.read(petServiceProvider);

      // 서버에 등록 요청
      final result = await service.registerCare(
        petId: state.petId,
        petName: state.petName,
        careName: state.careName,
        petAddress: state.petAddress,
        petPhone: state.petPhone,
      );

      return result.fold(
        // 성공
        onSuccess: (newPet) {
          _logger.info('어르신 등록 성공: ${newPet.petName}');

          // 전체 목록에 추가
          ref.read(careListProvider.notifier).addPet(newPet);

          // 등록된 어르신을 즉시 선택 상태로 설정
          ref.read(selectedPetProvider.notifier).update(newPet);

          // 등록 상태 초기화
          reset();

          return true;
        },

        // 실패
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

  /// 입력값 검증
  bool _validateState() {
    if (state.petId.isEmpty) {
      _logger.warning('검증 실패: 기기 ID 없음');
      return false;
    }

    if (state.petName.isEmpty) {
      _logger.warning('검증 실패: 어르신 이름 없음');
      return false;
    }

    if (state.careName.isEmpty) {
      _logger.warning('검증 실패: 돌봄 대상자 이름 없음');
      return false;
    }

    if (state.petAddress.isEmpty) {
      _logger.warning('검증 실패: 주소 없음');
      return false;
    }

    if (state.petPhone.isEmpty) {
      _logger.warning('검증 실패: 전화번호 없음');
      return false;
    }

    return true;
  }

  /// 현재 상태의 에러 메시지 반환 (검증용)
  String? get validationError {
    if (state.petId.isEmpty) return '기기 ID를 입력해주세요';
    if (state.petName.isEmpty) return '어르신 이름을 입력해주세요';
    if (state.careName.isEmpty) return '돌봄 대상자 이름을 입력해주세요';
    if (state.petAddress.isEmpty) return '주소를 입력해주세요';
    if (state.petPhone.isEmpty) return '전화번호를 입력해주세요';
    return null;
  }

  /// 등록 가능 여부
  bool get canSubmit => validationError == null;
}

// ═══════════════════════════════════════════════════════════════════════
// 3. Provider 정의
// ═══════════════════════════════════════════════════════════════════════

final petRegistrationProvider =
NotifierProvider<PetRegistrationNotifier, PetModel>(
      () => PetRegistrationNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════
// 4. 편의 Provider들
// ═══════════════════════════════════════════════════════════════════════

/// 등록 가능 여부
final canSubmitPetProvider = Provider<bool>((ref) {
  return ref.watch(petRegistrationProvider.notifier).canSubmit;
});

/// 검증 에러 메시지
final petValidationErrorProvider = Provider<String?>((ref) {
  return ref.watch(petRegistrationProvider.notifier).validationError;
});
