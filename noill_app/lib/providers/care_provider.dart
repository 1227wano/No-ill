import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_models.dart';
import 'auth_provider.dart';
import '../services/pet_service.dart'; // 실제 서비스 클래스 위치 확인
import '../core/network/dio_provider.dart'; // ✅ DioProvider 임포트 필요

// 1. CareServiceProvider 수정 (오류 4 해결: dio 주입)
final careServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider); // 앱에서 사용하는 dio 객체 가져오기
  return PetService(dio);
});

// 1. 관리 중인 어르신 목록을 관리하는 Notifier
class CareListNotifier extends StateNotifier<AsyncValue<List<PetRequest>>> {
  final Ref ref;

  CareListNotifier(this.ref) : super(const AsyncValue.loading());

  /// 서버에서 목록 가져오기
  Future<void> fetchCareList() async {
    final authState = ref.read(authProvider);

    // 🔍 1번 확인: 로그인 상태가 authenticated가 맞는지?
    print("🔍 [Debug] 현재 로그인 상태: ${authState.status}");

    // ✅ 오류 1 해결: auth_provider의 AuthState에는 .user가 없고 .userData가 있음
    if (!authState.isAuthenticated) {
      print("⚠️ [Debug] 로그인이 되어있지 않아 빈 리스트를 반환합니다.");
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final service = ref.read(careServiceProvider);
      final List<PetRequest> fetchedList = await service.fetchMyPets();

      // 🔍 2번 확인: 서버(혹은 Mock)에서 데이터를 진짜 가져왔는지?
      print("✅ [Debug] 가져온 데이터 갯수: ${fetchedList.length}개");

      state = AsyncValue.data(fetchedList);

      // 데이터 로드 후 선택된 ID가 없다면 첫 번째로 자동 설정
      if (fetchedList.isNotEmpty && ref.read(selectedPetIdProvider) == null) {
        ref.read(selectedPetIdProvider.notifier).state =
            fetchedList.first.petId;
      }
    } catch (e, stack) {
      print("❌ [Debug] 목록 로드 에러: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  /// ✅ [추가] 새로운 어르신 정보를 목록에 즉시 추가하는 메서드
  void addPet(PetRequest newPet) {
    // 현재 상태가 데이터(AsyncData)인 경우에만 실행
    state.whenData((currentList) {
      // 1. 중복 체크 (이미 같은 ID가 있다면 추가하지 않음)
      if (currentList.any((p) => p.petId == newPet.petId)) return;

      // 2. 기존 리스트에 새 항목을 추가하여 상태 업데이트
      state = AsyncValue.data([...currentList, newPet]);

      // 3. (옵션) 추가와 동시에 이 어르신을 선택된 상태로 변경
      ref.read(selectedPetIdProvider.notifier).state = newPet.petId;
    });
  }

  /// ✅ [신규] 로봇펫 + 어르신 정보 한 번에 등록
  /// 화면 1, 2에서 모은 데이터를 파라미터로 받습니다.
  Future<bool> registerPetAndSenior({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      final service = ref.read(careServiceProvider);

      // 서버에 한 번에 전송 (API 스펙에 맞춰 수정 필요)
      final PetRequest newPet = await service.registerCare(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      // 등록 성공 시 목록 갱신
      state.whenData((currentData) {
        state = AsyncValue.data([...currentData, newPet]);
        // 새로 등록한 기기를 즉시 선택 상태로 전환
        ref.read(selectedPetIdProvider.notifier).state = newPet.petId;
      });

      return true;
    } catch (e) {
      print("❌ 등록 오류: $e");
      return false;
    }
  }
}

final careListProvider =
    StateNotifierProvider<CareListNotifier, AsyncValue<List<PetRequest>>>((
      ref,
    ) {
      // 1. authProvider의 '상태'를 감시합니다.
      // 이제 로그인 상태가 바뀌면(initial -> authenticated) 이 코드 블록이 다시 실행됩니다.
      final authStatus = ref.watch(authProvider.select((s) => s.status));

      final notifier = CareListNotifier(ref);

      // 2. 만약 로그인 완료 상태라면 목록을 가져오도록 명령합니다.
      if (authStatus == AuthStatus.authenticated) {
        notifier.fetchCareList();
      }

      return notifier;
    });

// 현재 선택된 ID
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

// ✅ [오류 수정] 선택된 ID를 바탕으로 정보 실시간 계산
final selectedCareProvider = Provider<PetRequest?>((ref) {
  // careListProvider의 상태(AsyncValue)를 감시
  final listAsync = ref.watch(careListProvider);
  final selectedId = ref.watch(selectedPetIdProvider);

  // AsyncValue에서 데이터를 안전하게 꺼내 처리
  return listAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) return null;
      // 선택된 ID가 리스트에 있는지 확인, 없으면 첫 번째 항목 반환
      return list.firstWhere(
        (p) => p.petId == selectedId,
        orElse: () => list.first,
      );
    },
    orElse: () => null, // 로딩 중이거나 에러 시 null 반환
  );
});
