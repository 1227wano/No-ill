// 환경변수를 읽어 오는 파일
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {

  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    print('🔍 [ApiConstants] BASE_URL: $url');

    if (url == null || url.isEmpty) {
      return 'http://i14a301.p.ssafy.io';  // ⭐ /api 제거
    }

    return url;
  }

  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String logout = '/api/auth/logout';
  static const String registerPet = '/api/users/pets';
  static const String getMyPets = '/api/users/pets';
  static const String registerNotification = '/api/notifications/token';
}
