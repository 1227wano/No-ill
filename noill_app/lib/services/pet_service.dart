import 'package:dio/dio.dart';
import '../models/pet_models.dart';
import '../models/auth_models.dart';
import '../core/network/api_constants.dart';

class PetService {
  final Dio _dio;
  PetService(this._dio);

  // 오류 3 해결: registerPetAndSenior에서 부를 수 있도록 이름 통일 혹은 래핑
  Future<PetRequest> registerCare({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      // 💡 화면 1, 2의 데이터를 하나의 Request 객체로 합침
      final request = PetRegistrationRequest(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      final response = await _dio.post(
        ApiConstants.registerPet,
        data: request.toJson(),
      );

      // 서버 응답 데이터를 PetRequest 모델로 변환 (서버 response 구조에 맞춰 수정 필요)
      return PetRequest.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('등록 실패: ${e.message}');
    }
  }

  // 드롭다운에 들어갈 데이터 -> care_provider에 들어가는 데이터
  // 오류 2 해결: getMyPetList -> fetchMyPets로 이름 변경 (Provider와 통일)
  Future<List<PetRequest>> fetchMyPets() async {
    try {
      // 실제 API 호출 시:
      final response = await _dio.get(ApiConstants.getMyPets);
      // 🔍 [필수 확인] 서버가 보내준 진짜 JSON 구조를 콘솔에서 보세요.
      print("📡 [Server Raw Data]: ${response.data}");

      final List<dynamic> data = response.data;
      print("✅ [PetService] 서버에서 받은 실제 데이터 갯수: ${data.length}개");
      return data.map((e) => PetRequest.fromJson(e)).toList();
      // 테스트용 가짜 데이터 (유지)
      // await Future.delayed(const Duration(milliseconds: 500));
      // return [
      //   PetRequest(
      //     petId: "SERIAL_123",
      //     petName: "복순이",
      //     careName: "어머니 댁",
      //     petAddress: "서울",
      //     petPhone: "010-1111-2222",
      //   ),
      //   PetRequest(
      //     petId: "SERIAL_456",
      //     petName: "철수",
      //     careName: "아버지 댁",
      //     petAddress: "부산",
      //     petPhone: "010-3333-4444",
      //   ),
      // ];
    } on DioException catch (e) {
      print("❌ [API 에러]: ${e.response?.statusCode} - ${e.response?.data}");
      rethrow;
    }
  }

  // 어르신 인증
  Future<PetRequest?> connectPet(String petId) async {
    try {
      // 💡 POST /api/auth/pets/login 호출
      final response = await _dio.post(
        '/auth/pets/login',
        data: {'petId': petId},
      );
    } on DioException catch (e) {
      // 💡 403 에러가 나면 '이미 누군가 쓰고 있다'는 정보를 담아서 던져야 합니다.
      if (e.response?.statusCode == 403) {
        print('🚨 이미 등록된 기기입니다 (인가 거부)');
        // 여기서 null을 주기보다, 에러를 throw하거나 특정 플래그를 담은 객체를 줘야 합니다.
      }
      return null;
    }
  }
}
