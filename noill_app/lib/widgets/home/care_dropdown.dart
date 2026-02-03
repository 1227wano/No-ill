// 어르신 선택 드롭다운
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/care_provider.dart';
import '../atoms/custom_card.dart';

class CareDropdown extends ConsumerWidget {
  const CareDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careList = ref.watch(careListProvider);
    final selectedCare = ref.watch(selectedPetProvider);

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: careList.when(
          data: (list) => DropdownButton<String>(
            value: selectedCare?.petId,
            isExpanded: true,
            hint: const Text("등록된 어르신이 없습니다."),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            items: list
                .map(
                  (pet) => DropdownMenuItem(
                    value: pet.petId,
                    child: Text(
                      "${pet.careName} (${pet.petName})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) {
              if (id != null) {
                ref.read(selectedPetIdProvider.notifier).state = id;
              }
            },
          ),
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
          error: (err, _) =>
              const SizedBox(height: 48, child: Center(child: Text("목록 오류"))),
        ),
      ),
    );
  }
}
