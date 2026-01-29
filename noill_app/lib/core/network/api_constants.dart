// 환경변수를 읽어 오는 파일
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // 💡 이제 직접 주소를 적지 않고 안전하게 가져옵니다.
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://fallback.url';

  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String logout = '/api/auth/logout';
}
