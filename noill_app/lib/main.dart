// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/utils/result.dart';

// ✅ 리팩토링된 Providers/Services 임포트
import 'providers/auth_provider.dart';
import 'providers/care_provider.dart';
import 'providers/event_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/call_provider.dart';
import 'providers/fcm_provider.dart'; // 또는 services/fcm_service.dart
import 'services/fcm_service.dart';

// ✅ 모든 화면 임포트
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/accident/event_screen.dart';
import 'screens/onboarding/device_pairing_screen.dart';

// 1. 전역 내비게이터 키
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// 3. 메인 함수
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Firebase 초기화 (중복 초기화 방지)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 이미 초기화된 경우 무시 (핫 리스타트 등)
  }

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(ProviderScope(child: NoIllApp()));
}

// 4. 앱 초기화 로직 (Provider에서 처리)
class NoIllApp extends ConsumerStatefulWidget {
  const NoIllApp({super.key});

  @override
  ConsumerState<NoIllApp> createState() => _NoIllAppState();
}

class _NoIllAppState extends ConsumerState<NoIllApp> {
  final _logger = AppLogger('NoIllApp');

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 앱 전체 초기화
  Future<void> _initializeApp() async {
    try {
      _logger.info('앱 초기화 시작');

      final fcmService = ref.read(fcmServiceProvider);

      // FCM 초기화
      final initResult = await fcmService.initialize();
      initResult.fold(
        onSuccess: (_) => _logger.info('FCM 초기화 성공'),
        onFailure: (exception) =>
            _logger.error('FCM 초기화 실패: ${exception.message}'),
      );

      // 알림 클릭 리스너 설정
      await fcmService.setupNotificationClickListeners();

      // FCM 토큰 처리 (로그인 후 자동 처리됨)
      _logger.info('앱 초기화 완료');
    } catch (e, stackTrace) {
      _logger.error('앱 초기화 실패', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // ✅ 디자인 기준 사이즈를 고정합니다.
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'No-ill App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, widget) {
            // 별도의 Center나 Container로 가두지 않고 전체를 반환합니다.
            return widget!;
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/main': (context) => const MainScreen(),
            '/alarms': (context) => const RecentEventScreen(),
            '/device-pairing': (context) => const DevicePairingScreen(),
          },
        );
      },
    );
  }
}
