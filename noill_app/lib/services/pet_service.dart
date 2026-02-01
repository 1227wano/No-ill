import 'package:dio/dio.dart';
import '../models/pet_models.dart';
import '../models/auth_models.dart';
import '../core/network/api_constants.dart';

class PetService {
  final Dio _dio;
  PetService(this._dio);

  Future<bool> registerPet(PetRegistrationRequest request) async {
    try {
      print('🚀 [PetService] 펫 등록 요청: ${request.toJson()}');
      // POST /api/users/pets 엔드포인트 (명세 준수)
      final response = await _dio.post(
        ApiConstants.registerPet,
        data: request.toJson(),
      );
      print('✅ [PetService] 펫 등록 성공: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('❌ [PetService] 등록 실패');
      print('- 상태 코드: ${e.response?.statusCode}');
      print('- 에러 데이터: ${e.response?.data}');
      print('- 에러 메시지: ${e.message}');
      return false;
    }
  }

  // 드롭다운에 들어갈 데이터 -> care_provider에 들어가는 데이터
  Future<List<PetRequest>> getMyPetList() async {
    try {
      // 💡 실제 API가 생기면 아래 주석을 해제하세요.
      // final response = await _dio.get('/api/users/pets');
      // return (response.data['data'] as List).map((e) => PetRequest.fromJson(e)).toList();

      // 지금은 테스트용 가짜 데이터를 반환합니다.
      await Future.delayed(const Duration(milliseconds: 500)); // 통신하는 척!
      return [
        PetRequest(
          petId: "SERIAL_123",
          petName: "복순이",
          careName: "어머니 댁",
          petAddress: "서울",
          petPhone: "010-1111-2222",
        ),
        PetRequest(
          petId: "SERIAL_456",
          petName: "철수",
          careName: "아버지 댁",
          petAddress: "부산",
          petPhone: "010-3333-4444",
        ),
        PetRequest(
          petId: "N0111",
          petName: "노일이",
          careName: "김노인",
          petAddress: "서울시",
          petPhone: "010-2222-3333",
        ),
      ];
    } catch (e) {
      return []; // 에러 시 빈 리스트
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 서버에서 기존 어르신 정보를 담아서 보내준다면 모델로 변환
        return PetRequest.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // 404나 에러가 나면 '신규 기기'로 판단하거나 에러 처리
      print('❌ 연동 실패: $e');
      return null;
    }
  }
}
