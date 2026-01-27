// 환경변수를 읽어 오는 파일

class ApiConstants {
  // 컴파일 타임에 설정된 BASE_URL 값을 읽어옵니다.
  // 값이 없을 경우를 대비해 기본값(defaultValue)을 설정해두면 안전합니다.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  // 나머지 엔드포인트들은 baseUrl 뒤에 붙여서 사용합니다.
  // 인증
  static const String login = "/api/auth/login";
  static const String signup = "/api/auth/signup";
  static const String logout = "/api/auth/logout";
  // 일정 관리
  static const String schedule = "/api/schedules";
  // static const String elderlyList = "/elderly/list";
  // static const String accidentHistory = "/history/accidents";
}
