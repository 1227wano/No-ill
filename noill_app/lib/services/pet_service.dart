import 'package:dio/dio.dart';
import '../models/pet_models.dart';

class PetService {
  final Dio _dio;
  PetService(this._dio);

  Future<bool> registerPet(PetRegistrationRequest request) async {
    try {
      // API 엔드포인트는 백엔드와 상의하여 결정 (예: /pet)
      final response = await _dio.post('/users/pets', data: request.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ [PetService] 등록 실패: $e');
      return false;
    }
  }
}
