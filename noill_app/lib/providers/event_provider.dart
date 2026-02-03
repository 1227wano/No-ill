import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/models/event_models.dart';
import '../models/event_models.dart';
import 'care_provider.dart';
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';

final eventServiceProvider = Provider(
  (ref) => PetService(ref.read(dioProvider)),
);

// 모든 어르신의 사고 보고서를 통합하여 가져오는 프로바이더
// final eventReportProvider = FutureProvider<List<EventModel>>((ref) async {
//   final careListAsync = ref.watch(careListProvider);
//   final careList = careListAsync.value ?? [];
//   final service = ref.read(eventServiceProvider);

//   if (careList.isEmpty) return [];

//   List<EventModel> totalReports = [];

//   for (var pet in careList) {
//     try {
//       // 서버에서 해당 어르신의 전체 보고서(title, body, image 포함)를 가져옴
//       final reports = await service.fetchEvents(pet.petId);

//       if (reports.isNotEmpty) {
//         final namedReports = reports.map(
//           (r) => r.copyWith(careName: pet.careName),
//         );
//         totalReports.addAll(namedReports);
//       }
//     } catch (e) {
//       print("🚨 ${pet.careName} 보고서 로드 실패: $e");
//     }
//   }
//   return totalReports;
// });

final singlePetReportProvider = FutureProvider.family<List<EventModel>, String>(
  (ref, petId) async {
    final service = ref.read(eventServiceProvider);
    final reports = await service.fetchEvents(petId);

    // 최신순 정렬
    reports.sort((a, b) => b.eventTime.compareTo(a.eventTime));
    return reports;
  },
);
