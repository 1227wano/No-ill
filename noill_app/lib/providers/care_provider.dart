import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/pet_model.dart';
import 'auth_provider.dart';
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';

// 1. 서비스 프로바이더 (PetService 주입)
final careServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return PetService(dio);
});

// 2. 어르신 목록 관리 (AsyncNotifier로 최신화)
class CareListNotifier extends AsyncNotifier<List<PetModel>> {
  @override
  Future<List<PetModel>> build() async {
    // 💡 로그인 상태를 감시하여 인증된 경우에만 데이터를 가져옵니다.
    final authStatus = ref.watch(authProvider.select((s) => s.status));

    if (authStatus == AuthStatus.authenticated) {
      return await ref.read(careServiceProvider).fetchMyPets();
    }
    return [];
  }

  /// ✅ 새로운 어르신을 목록에 즉시 추가 (UI 즉시 반영)
  void addPet(PetModel newPet) {
    state.whenData((currentList) {
      // 중복 체크 후 상태 업데이트
      if (!currentList.any((p) => p.petId == newPet.petId)) {
        state = AsyncData([...currentList, newPet]);
      }
    });
  }

  /// ✅ 로봇 + 어르신 정보 등록 및 목록 갱신
  Future<bool> registerPetAndSenior({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      final service = ref.read(careServiceProvider);

      // 서버 전송 및 응답 수신
      final newPet = await service.registerCare(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      // 목록에 추가하고 즉시 선택 상태로 변경
      addPet(newPet);
      ref.read(selectedPetProvider.notifier).state = newPet;

      return true;
    } catch (e) {
      print("❌ [CareListNotifier] 등록 오류: $e");
      return false;
    }
  }
}

// 3. 프로바이더 정의
final careListProvider =
    AsyncNotifierProvider<CareListNotifier, List<PetModel>>(() {
      return CareListNotifier();
    });

// ------------------------------------------------------------------
// 4. 선택된 어르신 정보 관리 (Selection States)
// ------------------------------------------------------------------

/// 현재 선택된 어르신 '객체 전체' 관리 (Single Source of Truth)
final selectedPetProvider = StateProvider<PetModel?>((ref) => null);

/// ✅ [선택된 ID] 실시간 계산
final selectedPetIdProvider = StateProvider<String?>((ref) {
  final pet = ref.watch(selectedPetProvider);
  return pet?.petId; //
});

/// ✅ [선택된 No] 실시간 계산 (서버 DB용)
final selectedPetNoProvider = Provider<int?>((ref) {
  final pet = ref.watch(selectedPetProvider);
  return pet?.petNo; //
});
