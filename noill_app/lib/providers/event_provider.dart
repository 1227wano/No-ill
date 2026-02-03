import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noill_app/models/event_model.dart';
import '../services/pet_service.dart';
import '../core/network/dio_provider.dart';

final eventServiceProvider = Provider(
  (ref) => PetService(ref.read(dioProvider)),
);

// 2. 💡 [핵심 추가] 실시간 푸시 알림 데이터를 담는 보관함
// 초기값은 null (아무 사고도 안 일어난 상태)
final recentEventProvider = StateProvider<EventModel?>((ref) => null);
// final recentEventProvider = StateProvider<EventModel?>((ref) {
//   return EventModel(
//     eventNo: 1,
//     eventTime: DateTime.now(),
//     title: "🚨 실시간 사고 감지 테스트",
//     body: "서버 images/ 폴더의 첫 번째 사진을 불러오는 중입니다.",
//     // 서버에 실제 있는 파일 주소
//     imageUrl:
//         "http://i14a301.p.ssafy.io:8080/images/07ea9388-1b83-40b5-b45a-200504f40294.png",
//     petId: "N0111",
//   );
// });

// 3. 기존의 singlePetReportProvider (기존 유지)
final singlePetReportProvider = FutureProvider.family<List<EventModel>, String>(
  (ref, petId) async {
    final service = ref.read(eventServiceProvider);
    final reports = await service.fetchEvents(petId);
    reports.sort((a, b) => b.eventTime.compareTo(a.eventTime));
    return reports;
  },
);
