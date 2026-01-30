import 'package:dio/dio.dart';
import '../models/pet_models.dart';
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
}
