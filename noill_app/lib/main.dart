import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';

import 'package:noill_app/core/theme/app_theme.dart';
import 'package:noill_app/screens/auth/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'services/fcm_service.dart';

// ✅ 백그라운드 핸들러 (최상위 유지)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 [FCM] 백그라운드 메시지 수신: ${message.data}');
  await FcmService.showNotificationBackground(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 메시지 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ 1. 컨테이너 생성
  final container = ProviderContainer();

  // ✅ 2. 초기화 함수 호출 (파라미터 수정)
  await _initializeNotification(container);

  runApp(
    // ✅ 'parent' 대신 'UncontrolledProviderScope'를 쓰면 에러가 안 납니다!
    UncontrolledProviderScope(container: container, child: const NoIllApp()),
  );
}

// 💡 함수 구조도 더 단순하게 바꿨습니다.
Future<void> _initializeNotification(ProviderContainer container) async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // ✅ 여기서 fcmServiceProvider를 통해 서비스를 가져와 초기화합니다.
    await container.read(fcmServiceProvider).initialize();
    print('✅ [FCM] 초기화 성공');
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
          title: 'No-ill App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const MainScreen(),
          },
        );
      },
    );
  }
}
