import 'package:dio/dio.dart';
import 'package:noill_app/models/event_model.dart';
import '../models/pet_model.dart'; // ✅ 통합 모델 하나만 사용
import '../core/network/api_constants.dart';

class PetService {
  final Dio _dio;
  PetService(this._dio);

  /// 1. 어르신/로봇 정보 등록 (POST)
  Future<PetModel> registerCare({
    required String petId,
    required String petName,
    required String careName,
    required String petAddress,
    required String petPhone,
  }) async {
    try {
      // ✅ PetModel 객체 생성 (petNo는 등록 전이라 null)
      final pet = PetModel(
        petId: petId,
        petName: petName,
        careName: careName,
        petAddress: petAddress,
        petPhone: petPhone,
      );

      final response = await _dio.post(
        ApiConstants.registerPet,
        data: pet.toJson(), // ✅ 통합된 toJson 사용
      );

      // 서버 응답 구조가 { "data": { ... } } 인 경우 처리
      return PetModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('등록 실패: ${e.message}');
    }
  }

  /// 2. 내 어르신 목록 조회 (GET) -> care_provider와 연동
  Future<List<PetModel>> fetchMyPets() async {
    try {
      final response = await _dio.get(ApiConstants.getMyPets);
      print("📡 [Server Raw Data]: ${response.data}");

      final List<dynamic> data = response.data;
      // ✅ PetModel.fromJson으로 통일하여 변환
      return data.map((e) => PetModel.fromJson(e)).toList();
    } on DioException catch (e) {
      print("❌ [API 에러]: ${e.response?.statusCode} - ${e.response?.data}");
      rethrow;
    }
  }

  /// 3. 기기 연결/로그인 (POST)
  Future<PetModel?> connectPet(String petId) async {
    try {
      final response = await _dio.post(
        '/auth/pets/login',
        data: {'petId': petId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return PetModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('🚨 이미 등록된 기기입니다 (인가 거부)');
      }
      return null;
    }
  }

  /// 4. 사고 기록 가져오기 (기존 로직 유지)
  Future<List<EventModel>> fetchEvents(String petId) async {
    try {
      final response = await _dio.get('/events/$petId');
      final List<dynamic> data = response.data;
      return data.map((json) => EventModel.fromJson(json, petId)).toList();
    } on DioException catch (e) {
      print("❌ [사고 기록 API 에러]: ${e.response?.statusCode}");
      rethrow;
    }
  }
}
