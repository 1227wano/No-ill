import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/screens/auth/welcome_screen.dart';

import 'firebase_options.dart';
import 'package:noill_app/core/theme/app_theme.dart';

// ✅ 화면 및 서비스 임포트
import 'screens/main_screen.dart';
import 'screens/accident/alarm_screen.dart';
import 'screens/accident/event_screen.dart';
import 'services/fcm_service.dart';
import 'providers/fcm_provider.dart';

// 1. 전역 내비게이터 키 (최상위 선언)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showNotificationBackground(message);
} //

// 3. 메인 함수
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("🔥 [Firebase] 신규 초기화 성공");
    }
  } catch (e) {
    print("❌ [Firebase] 초기화 중 예외 발생: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  await initializeNotification(container);

  runApp(
    UncontrolledProviderScope(container: container, child: const NoIllApp()),
  );
}

// 4. 알림 초기화 로직
Future<void> initializeNotification(ProviderContainer container) async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    if (token != null) {
      print('🚀 [FCM TOKEN]: $token');
      final fcmLogic = container.read(fcmProvider);

      // 서비스 인스턴스를 통한 초기화
      await fcmLogic.service.sendTokenToServer(token);
      await fcmLogic.service.initialize();
      print('✅ [FCM] 초기화 및 토큰 저장 완료');
    }
  } catch (e) {
    print('❌ [FCM] 초기화 에러: $e');
  }
}

// 5. 앱 클래스
class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852), // iPhone 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'No-ill App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const MainScreen(),
            '/alarm': (context) => const AlarmScreen(),
            '/event_screen': (context) => const EventScreen(),
          },
        );
      },
    );
  }
}
