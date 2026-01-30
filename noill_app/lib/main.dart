import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:noill_app/core/theme/app_theme.dart';
import 'package:noill_app/screens/auth/splash_screen.dart';
import 'screens/main_screen.dart';

// ✅ 1. 백그라운드 메시지 핸들러의 정확한 위치: 최상위(Top-level)
// 클래스 외부, main 함수 외부에 위치해야 합니다.
@pragma('vm:entry-point') // 💡 중요: 별도의 Isolate에서 실행되기 위해 필요합니다.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서 실행될 때 Firebase를 다시 초기화해줘야 합니다.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📬 [FCM] 백그라운드 메시지 수신');
  print('   - 제목: ${message.notification?.title}');
  print('   - 내용: ${message.notification?.body}');
  print('   - 데이터: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ 2. 핸들러 등록은 여기서 딱 한 번만!
  // 앱이 종료된 상태에서도 이 함수가 입구 역할을 하게 됩니다.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: NoIllApp()));

  // 권한 요청 및 포그라운드 설정 진행
  _initializeNotification();
}

Future<void> _initializeNotification() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 권한 요청
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [FCM] 사용자가 알림 권한을 승인했습니다');
    } else {
      print('❌ [FCM] 알림 권한 거부 또는 설정 필요');
    }

    // 💡 [참고] 여기서는 이미 main에서 등록했으므로
    // onBackgroundMessage를 또 등록할 필요가 없습니다.

    print('✅ [FCM] 알림 초기화 완료');
  } catch (e) {
    print('❌ 알림 초기화 실패: $e');
  }
}

class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No-ill App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
