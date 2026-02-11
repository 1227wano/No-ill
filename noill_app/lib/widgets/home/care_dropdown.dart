import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import '../../providers/care_provider.dart';
// import '../atoms/custom_card.dart';

class CareDropdown extends ConsumerWidget {
  const CareDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 전체 어르신 목록 구독 (AsyncValue)
    final careList = ref.watch(careListProvider);

    // 2. 현재 선택된 '객체'와 'ID'를 모두 감시합니다.
    // 드롭다운의 텍스트가 안 바뀌는 문제를 해결하기 위해 selectedPetIdProvider를 직접 사용합니다.
    final selectedCare = ref.watch(selectedPetProvider);
    final selectedId = ref.watch(selectedPetIdProvider);

    // 선택 여부 판단
    final bool isSelected = selectedId != null && selectedId.isNotEmpty;

    return Container(
      // 선택 시 테두리 색상과 두께를 동적으로 변경
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // CustomCard와 동일한 라운드값
        border: Border.all(
          color: isSelected ? NoIllColors.primary : Colors.grey.shade200,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: careList.when(
          data: (list) {
            // 목록이 비어있지 않은데 선택된 ID가 없다면 첫 번째 항목을 기본값으로 설정
            // (이미 provider에서 처리 중이라면 생략 가능하지만 UI 안정성을 위해 권장)
            final String? currentId =
                (selectedId != null && selectedId.isNotEmpty)
                ? selectedId
                : selectedCare?.petId;

            return DropdownButton<String>(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              // 🎯 핵심: 이 value가 list 내의 특정 petId와 '완벽하게' 일치해야 화면이 바뀝니다.
              value: (currentId == null || currentId.isEmpty)
                  ? null
                  : currentId,
              isExpanded: true,
              hint: const Text("등록된 어르신이 없습니다."),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isSelected ? NoIllColors.primary : Colors.grey,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              items: list.map((pet) {
                return DropdownMenuItem<String>(
                  value: pet.petId,
                  child: Text(
                    // 🎯 요청하신 형식: 어르신 이름 (petId)
                    "${pet.careName} (${pet.petId})",
                    style: TextStyle(
                      fontSize: 16,
                      // 선택된 텍스트 강조
                      fontWeight: isSelected && currentId == pet.petId
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected && currentId == pet.petId
                          ? NoIllColors.primary
                          : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  print("✅ 선택된 어르신 ID: $id");
                  // selectedPetProvider를 직접 업데이트 (selectedPetIdProvider는 파생 Provider)
                  final pickedPet = list.firstWhere((p) => p.petId == id);
                  ref.read(selectedPetProvider.notifier).update(pickedPet);
                }
              },
            );
          },
          // 로딩 중 디자인
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          // 에러 발생 시 디자인
          error: (err, _) => const SizedBox(
            height: 48,
            child: Center(child: Text("어르신 목록을 불러오지 못했습니다.")),
          ),
        ),
      ),
    );
  }
}
