import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_models.dart';
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';

// 1. 서비스 프로바이더 (통신 도구)
final petServiceProvider = Provider((ref) => PetService(ref.read(dioProvider)));

// 2. Notifier 클래스 정의 (상태 변화 관리)
// StateNotifier 대신 Notifier를 상속받습니다.
class PetRegistrationNotifier extends Notifier<PetRegistrationRequest> {
  @override
  PetRegistrationRequest build() {
    // 초기 상태를 설정합니다.
    return PetRegistrationRequest();
  }

  // 기기 번호 업데이트 (DevicePairingScreen)
  void updatePetId(String id) {
    state = state.copyWith(petId: id);
  }

  // 어르신 프로필 업데이트 (ElderlyProfileRegistrationScreen)
  void updateProfile({
    required String name,
    required String address,
    required String phone,
  }) {
    state = state.copyWith(
      careName: name,
      petAddress: address,
      petPhone: phone,
    );
  }

  // 최종 서버 전송
  Future<bool> submit() async {
    final service = ref.read(petServiceProvider);
    return await service.registerPet(state);
  }
}

// 3. 프로바이더 정의 (외부에서 접근하는 통로)
// StateNotifierProvider 대신 NotifierProvider를 사용합니다.
final petRegistrationProvider =
    NotifierProvider<PetRegistrationNotifier, PetRegistrationRequest>(
      () => PetRegistrationNotifier(),
    );
