import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_model.dart'; // ✅ 통합 모델 사용
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';
import 'care_provider.dart'; // careListProvider, selectedPetProvider가 있는 곳

// 1. 서비스 프로바이더
final petServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return PetService(dio);
});

// 2. Notifier 클래스 정의
class PetRegistrationNotifier extends Notifier<PetModel> {
  @override
  PetModel build() {
    // 초기값 설정: PetModel의 필수값인 petId를 빈 문자열로 초기화
    return PetModel(petId: '');
  }

  // ✅ copyWith를 사용하여 상태 업데이트 로직 간소화
  void updatePetId(String id) {
    state = state.copyWith(petId: id);
  }

  void updatePetName(String name) {
    state = state.copyWith(petName: name);
  }

  void updateProfile({
    required String address,
    required String phone,
    required String careName,
  }) {
    state = state.copyWith(
      petAddress: address,
      petPhone: phone,
      careName: careName,
    );
  }

  /// ✅ 최종 서버 전송 및 상태 동기화 로직
  Future<bool> submit() async {
    final service = ref.read(petServiceProvider);

    try {
      // 1. 서버에 등록 요청
      final newPet = await service.registerCare(
        petId: state.petId,
        petName: state.petName,
        careName: state.careName,
        petAddress: state.petAddress,
        petPhone: state.petPhone,
      );

      // 2. 등록 성공 시, 전체 목록에 새 데이터 추가
      // (careListProvider의 notifier가 addPet 메서드를 가지고 있어야 합니다)
      ref.read(careListProvider.notifier).addPet(newPet);

      // 3. ⭐ 가장 중요한 부분: 등록된 어르신을 즉시 '선택된 상태'로 변경
      // selectedPetProvider를 업데이트하면 파생된 ID, No 프로바이더도 자동 갱신됩니다.
      ref.read(selectedPetProvider.notifier).state = newPet;

      return true;
    } catch (e) {
      print('❌ 등록 실패: $e');
      return false;
    }
  }
}

// 3. 프로바이더 정의
final petRegistrationProvider =
    NotifierProvider<PetRegistrationNotifier, PetModel>(
      () => PetRegistrationNotifier(),
    );
