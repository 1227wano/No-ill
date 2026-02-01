// lib/providers/care_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_models.dart';
import '../services/pet_service.dart';
import 'pet_provider.dart'; // petServiceProvider를 쓰기 위해 필요

// 1. 서버에서 어르신 목록을 가져오는 프로바이더
final careListProvider = FutureProvider<List<PetRequest>>((ref) async {
  final petService = ref.read(petServiceProvider);
  return await petService.getMyPetList();
});

// 2. 현재 선택된 어르신의 ID를 관리하는 바구니 (이게 없어서 에러가 났을 거예요!)
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

// 3. ID를 바탕으로 선택된 어르신 정보를 실시간으로 계산해주는 프로바이더
final selectedCareProvider = Provider<PetRequest?>((ref) {
  final list = ref.watch(careListProvider).value ?? [];
  final selectedId = ref.watch(selectedPetIdProvider);

  if (list.isEmpty) return null;
  if (selectedId == null) return list.first; // 선택된 게 없으면 첫 번째 어르신 반환

  return list.firstWhere(
    (p) => p.petId == selectedId,
    orElse: () => list.first,
  );
});
