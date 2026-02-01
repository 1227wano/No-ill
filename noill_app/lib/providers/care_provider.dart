// lib/providers/care_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_models.dart';
import 'auth_provider.dart';
import 'pet_provider.dart';
import '../services/pet_service.dart';

// 1. 관리 중인 어르신 목록을 관리하는 핵심 바구니 (Notifier)
class CareListNotifier extends StateNotifier<List<PetRequest>> {
  final Ref ref;

  // 생성 시점에 초기 데이터를 가져옵니다.
  CareListNotifier(this.ref) : super([]) {
    _initializeList();
  }

  // 💡 내부용 초기화와 외부용 refresh를 통합하여 관리의 효율성을 높입니다.
  Future<void> _initializeList() async {
    final authState = ref.read(authProvider);
    final userName = authState.userData?.userName ?? "";

    // API가 나오면 이 하드코딩 영역이 'state = await petService.getMyPetList();'로 바뀝니다.
    if (userName == "기획자") {
      state = [
        PetRequest(
          petId: "REAL_ID_1",
          petName: "복순이",
          careName: "어머니 댁",
          petAddress: "서울시 노원구",
          petPhone: "010-1234-5678",
        ),
      ];
    } else if (userName == "개발자") {
      state = [
        PetRequest(
          petId: "REAL_ID_2",
          petName: "철수",
          careName: "아버지 댁",
          petAddress: "부산시 해운대구",
          petPhone: "010-9876-5432",
        ),
      ];
    } else {
      state = [];
    }

    // 초기 선택 로직 (이미 ID가 설정되어 있다면 유지, 없다면 첫 번째 선택)
    if (state.isNotEmpty && ref.read(selectedPetIdProvider) == null) {
      ref.read(selectedPetIdProvider.notifier).state = state.first.petId;
    }
  }

  void addPet(PetRequest pet) {
    if (!state.any((p) => p.petId == pet.petId)) {
      state = [...state, pet];
      // 💡 새로 등록한 기기를 즉시 선택 상태로 전환하는 UX 추가
      ref.read(selectedPetIdProvider.notifier).state = pet.petId;
    }
  }
}

// 2. 위 Notifier를 앱 전체에 공유하는 프로바이더
final careListProvider =
    StateNotifierProvider<CareListNotifier, List<PetRequest>>((ref) {
      return CareListNotifier(ref);
    });

// 3. 현재 선택된 어르신의 ID (기존 유지)
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

// 4. 선택된 ID를 바탕으로 정보를 실시간 계산 (기존 유지하되 list 관찰 방식 수정)
final selectedCareProvider = Provider<PetRequest?>((ref) {
  // careListProvider가 StateNotifierProvider이므로 바로 리스트를 얻습니다.
  final list = ref.watch(careListProvider);
  final selectedId = ref.watch(selectedPetIdProvider);

  if (list.isEmpty) return null;

  // 선택된 ID가 없거나 리스트에 없는 ID라면 첫 번째 항목 반환
  return list.firstWhere(
    (p) => p.petId == selectedId,
    orElse: () => list.first,
  );
});
