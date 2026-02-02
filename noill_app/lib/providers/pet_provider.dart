import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/models/pet_models.dart';
import '../models/auth_models.dart'; // PetRequest가 있는 파일
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';
import 'care_provider.dart'; // ✅ 등록 성공 후 목록 갱신을 위해 필요

// 1. 서비스 프로바이더 (Dio 주입 방식 통일)
final petServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return PetService(dio);
});

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
  // 강제 타입 변경하지 말고 명시적 변경 필요
  /// ✅ [수정] 최종 서버 전송 로직
  Future<bool> submit() async {
    final service = ref.read(petServiceProvider);

    try {
      // 1. 서비스의 바뀐 파라미터 형식에 맞춰 호출
      // state에 담긴 임시 데이터들을 하나씩 꺼내서 전달합니다.
      final newPet = await service.registerCare(
        petId: state.petId, // 화면 1 입력값
        petName: state.petName, // 화면 1 입력값
        careName: state.careName, // 화면 2 입력값
        petAddress: state.petAddress, // 화면 2 입력값
        petPhone: state.petPhone, // 화면 2 입력값
      );

      // 2. 등록 성공 시, 전체 어르신 목록(careListProvider)에 새 데이터 추가
      // 이렇게 해야 메인 화면으로 돌아갔을 때 새로고침 없이 바로 보입니다.
      ref.read(careListProvider.notifier).addPet(newPet);

      // 3. 등록된 기기를 즉시 선택 상태로 변경
      ref.read(selectedPetIdProvider.notifier).state = newPet.petId;

      return true;
    } catch (e) {
      print('❌ 등록 실패: $e');
      return false;
    }
  }
}

// 3. 프로바이더 정의
final petRegistrationProvider =
    NotifierProvider<PetRegistrationNotifier, PetRequest>(
      () => PetRegistrationNotifier(),
    );
