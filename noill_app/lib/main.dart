import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:noill_app/core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'screens/accident/alarm_screen.dart';

import 'services/fcm_service.dart';
import 'providers/fcm_provider.dart';

// ✅ 백그라운드 핸들러 (최상위 유지)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 💡 수정: 앱이 없을 때만 초기화
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print('📬 [FCM] 백그라운드 메시지 수신: ${message.data}');
  await FcmService.showNotificationBackground(message);
}

// 💡 1. 전역 내비게이터 키 생성 (MaterialApp 바깥에 선언)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 💡 수정: 중복 방지 로직
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("🔥 [Firebase] 신규 초기화 성공");
    } else {
      Firebase.app(); // 이미 있으면 기존 앱 연결
      print("🔥 [Firebase] 기존 앱 연결됨");
    }
  } catch (e) {
    print("❌ [Firebase] 초기화 중 예외 발생: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  await _initializeNotification(container);

  runApp(
    UncontrolledProviderScope(container: container, child: const NoIllApp()),
  );
}

Future<void> _initializeNotification(ProviderContainer container) async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    print('🚀 [FCM TOKEN]: $token');

    if (token != null) {
      // 💡 [핵심] fcmProvider를 통해 서버 DB에 토큰 저장!
      // fcm_provider.dart에 정의된 fcmProvider 이름을 정확히 사용해야 합니다.
      final fcmLogic = container.read(fcmProvider);

      // 서버로 토큰 전송 시도
      await fcmLogic.service.sendTokenToServer(token);

      // 리스너 및 초기화 실행
      await fcmLogic.service.initialize();

      print('✅ [DB] 토큰 저장 및 FCM 초기화 성공');
    }
  } catch (e) {
    print('❌ [FCM] 초기화 에러: $e');
  }
}

class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        393,
        852,
      ), // 👈 기획서(Figma)의 기준 사이즈를 적으세요 (보통 iPhone 14/15 기준)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // 키를 꽂아서 app push 누르면 알람 화면으로 이동할 수 있도록!
          title: 'No-ill App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const MainScreen(),
            // 💡 3. 빨간 창 방지: 알림 화면 경로 등록!
            '/alarms': (context) => const AlarmScreen(),
          },
        );
      },
    );
  }
}
