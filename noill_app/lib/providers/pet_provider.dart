import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/models/pet_models.dart';
import '../models/auth_models.dart'; // PetRequest가 있는 파일
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';

// 1. 서비스 프로바이더
final petServiceProvider = Provider((ref) => PetService(ref.read(dioProvider)));

// 2. Notifier 클래스 정의
// 💡 PetRegistrationRequest 대신 실제 모델명인 PetRequest를 사용합니다.
class PetRegistrationNotifier extends Notifier<PetRequest> {
  @override
  PetRequest build() {
    // 초기값 설정 (PetRequest의 모든 필드를 빈 값으로 초기화)
    return PetRequest(
      petId: '',
      petName: '',
      petAddress: '',
      petPhone: '',
      careName: '',
    );
  }

  // 기기 ID 업데이트
  void updatePetId(String id) {
    state = PetRequest(
      petId: id,
      petName: state.petName,
      petAddress: state.petAddress,
      petPhone: state.petPhone,
      careName: state.careName,
    );
  }

  // 기기 이름(별칭) 업데이트
  void updatePetName(String name) {
    state = PetRequest(
      petId: state.petId,
      petName: name,
      petAddress: state.petAddress,
      petPhone: state.petPhone,
      careName: state.careName,
    );
  }

  // 어르신 프로필 업데이트
  void updateProfile({
    required String address,
    required String phone,
    required String careName,
  }) {
    state = PetRequest(
      petId: state.petId,
      petName: state.petName,
      petAddress: address,
      petPhone: phone,
      careName: careName,
    );
  }

  // 최종 서버 전송
  Future<bool> submit() async {
    final service = ref.read(petServiceProvider);
    return await service.registerPet(state as PetRegistrationRequest);
  }
}

// 3. 프로바이더 정의
final petRegistrationProvider =
    NotifierProvider<PetRegistrationNotifier, PetRequest>(
      () => PetRegistrationNotifier(),
    );
