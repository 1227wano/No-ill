// 전체 앱의 진입점
// 모든 화면의 일관성 담당
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// firebase
import 'package:firebase_core/firebase_core.dart'; // 👈 추가
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 추가
import 'firebase_options.dart'; // 👈 CLI가 만들어준 파일 임포트

import 'package:noill_app/core/theme/app_theme.dart';
import 'package:noill_app/screens/auth/splash_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 작업을 main 함수에서 사용하기 위해 필요

  // 환경변수 로드
  await dotenv.load(fileName: ".env");

  // firebase 초기화 ('기다리기')
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 앱을 먼저 실행해 화면 띄우기
  runApp(const ProviderScope(child: NoIllApp()));

  // 권한 요청, 토큰 추출은 화면 띄운 후 별도 진행
  _initializeNotification();
}

// 별도의 함수로 분리해서 관리하면 가독성이 좋아집니다.
Future<void> _initializeNotification() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 권한 요청
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // FCM 토큰 가져오기
    // ※ 웹에서는 VAPID 키가 없으면 여기서 응답이 없을 수 있습니다.
    String? fcmToken = await messaging.getToken(
      vapidKey:
          "BLyYLeyyrWUkeSUJHUXjBLeGfHNus1-CNvH2kJK1Nm6MwWqEUwPml8R-nDaM7ynHCywMezpAabuLACfsaepYyB0",
    );

    print('🚀 [FCM TOKEN] : $fcmToken');
  } catch (e) {
    print('❌ 알림 초기화 실패: $e');
  }
}

class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No-ill App',
      theme: AppTheme.lightTheme.copyWith(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // 시작점 설정
        '/home': (context) => const MainScreen(),
        // alias used in some places
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
