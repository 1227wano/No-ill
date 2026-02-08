// lib/core/utils/logger.dart

import 'package:logger/logger.dart';

// 전역 Logger 인스턴스
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,        // 스택 트레이스 줄 수
    errorMethodCount: 5,   // 에러 시 스택 트레이스
    lineLength: 50,        // 로그 줄 길이
    colors: true,          // 컬러 출력
    printEmojis: true,     // 이모지 사용
    printTime: true,       // 시간 표시
  ),
  level: Level.debug,      // 개발: debug, 프로덕션: warning
);

// 각 클래스별 전용 Logger
class AppLogger {
  final String className;
  final Logger _logger;

  AppLogger(this.className) : _logger = appLogger;

  void debug(String message) => _logger.d('[$className] $message');
  void info(String message) => _logger.i('[$className] $message');
  void warning(String message) => _logger.w('[$className] $message');
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$className] $message', error: error, stackTrace: stackTrace);
  }
}
