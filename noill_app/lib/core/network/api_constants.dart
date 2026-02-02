// 환경변수를 읽어 오는 파일
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // 💡 이제 직접 주소를 적지 않고 안전하게 가져옵니다.
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://fallback.url';

  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String registerPet = '/users/pets';
  static const String getMyPets = '/users/pets';
  static const String registerNotification = '/notifications/token';
}
