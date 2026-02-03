import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/care_provider.dart'; // 어르신 목록 프로바이더 경로 확인

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 등록된 어르신 목록(PetModel 리스트)을 구독합니다.
    final careListAsync = ref.watch(careListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "관리 어르신 목록",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: careListAsync.when(
        data: (careList) {
          if (careList.isEmpty) {
            return const Center(child: Text("등록된 어르신 정보가 없습니다."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: careList.length,
            itemBuilder: (context, index) {
              final pet = careList[index];
              return _buildElderCard(context, pet);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("목록 로드 중 오류 발생: $err")),
      ),
    );
  }

  // 어르신 개별 카드 위젯
  Widget _buildElderCard(BuildContext context, dynamic pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.orangeAccent.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.orangeAccent),
        ),
        title: Text(
          "${pet.careName} 어르신",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "기기 ID: ${pet.petId}",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: () {
          // 2. 💡 클릭 시 상세 보고서 화면(EventScreen)으로 이동하며 필요한 인자를 넘깁니다.
          Navigator.pushNamed(
            context,
            '/event_screen',
            arguments: {'petId': pet.petId, 'careName': pet.careName},
          );
        },
      ),
    );
  }
}
