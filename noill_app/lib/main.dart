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
  // ※ 로그인 후 auth_provider에서 자동으로 FCM이 처리됩니다.
  _initializeNotification();
}

// 별도의 함수로 분리해서 관리하면 가독성이 좋아집니다.
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
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ [FCM] 임시 권한만 승인되었습니다');
    } else {
      print('❌ [FCM] 사용자가 알림 권한을 거부했습니다');
      return;
    }

    // 🔥 [개선] 백그라운드 메시지 핸들러 등록
    // (앱이 완전히 종료된 상태에서 메시지를 받을 때)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print('✅ [FCM] 알림 초기화 완료');
  } catch (e) {
    print('❌ 알림 초기화 실패: $e');
  }
}

// 🔥 [새로운 함수] 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서 Firebase를 다시 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📬 [FCM] 백그라운드 메시지 수신');
  print('   - 제목: ${message.notification?.title}');
  print('   - 내용: ${message.notification?.body}');
  print('   - 데이터: ${message.data}');
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
