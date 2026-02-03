import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/models/event_model.dart';
import 'package:noill_app/providers/call_privoder.dart';
import 'package:noill_app/providers/event_provider.dart';
import 'package:noill_app/screens/auth/welcome_screen.dart';

import 'firebase_options.dart';
import 'package:noill_app/core/theme/app_theme.dart';

// ✅ 화면 및 서비스 임포트
import 'screens/main_screen.dart';
import 'screens/accident/alarm_screen.dart';
import 'screens/accident/event_screen.dart';
import 'providers/fcm_provider.dart';

// 1. 전역 내비게이터 키 (최상위 선언)
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

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 💡 [여기입니다!] 실물 기기의 새로운 토큰을 가져와 콘솔에 찍기
  String? token = await FirebaseMessaging.instance.getToken();

  print("---------------------------------------");
  print("🚀 [FCM TOKEN]: $token"); // 👈 이 값을 복사해서 Firebase 콘솔에 넣으세요!
  print("---------------------------------------");

  // Riverpod 컨테이너 생성
  final container = ProviderContainer();

  // 🔔 [핵심 수정] 포그라운드 리스너 위치 및 로직
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   if (message.data.isNotEmpty) {
  //     const String baseUrl = "http://i14a301.p.ssafy.io:8080";

  //     // 1. eventNo 변환 (String -> int)
  //     // 데이터가 없으면 0, 있으면 숫자로 바꿉니다.
  //     final int eventNo = int.tryParse(message.data['eventNo'] ?? '0') ?? 0;

  //     // 2. 파일명 낚아채기
  //     final String? fileName = message.data['imageUrl'];

  //     if (fileName != null && fileName.isNotEmpty) {
  //       final String finalImageUrl = "$baseUrl/images/$fileName";

  //       // 3. 🧩 EventModel 생성 (기존 필드 모두 포함)
  //       final newEvent = EventModel(
  //         eventNo: eventNo,
  //         eventTime: DateTime.now(), // 실시간 사고이므로 현재 시간을 넣어줍니다.
  //         title: message.data['title'] ?? "낙상 사고 발생",
  //         body: message.data['body'] ?? "어르신의 상태를 확인해 주세요.",
  //         imageUrl: finalImageUrl,
  //         petId: message.data['petId'] ?? "N0111", // 데이터에 없으면 기본값 사용
  //       );

  //       print("🚀 [FCM] 모델 생성 및 주소 조립 완료: ${newEvent.imageUrl}");

  //       // 4. 📦 보관함(Provider) 업데이트
  //       container.read(recentEventProvider.notifier).state = newEvent;

  //       print("📸 이미지 로딩 준비 완료: ${newEvent.imageUrl}");
  //     }
  //   }
  // });

  // TEST
  // main.dart의 onMessage 리스너 부분
  // main.dart의 리스너 부분
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 신호가 도착하긴 했습니다!");

    // 1. 우선 Data 주머니 확인, 없으면 Notification 주머니에서 제목/내용이라도 가져옴
    String? title = message.data['title'] ?? message.notification?.title;
    String? body = message.data['body'] ?? message.notification?.body;
    String? imageUrl =
        message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

    if (imageUrl != null) {
      container.read(recentEventProvider.notifier).state = EventModel(
        eventNo: 0,
        eventTime: DateTime.now(),
        title: title ?? "낙상 사고 발생",
        body: body ?? "어르신 상태를 확인하세요.",
        imageUrl: imageUrl,
        petId: message.data['petId'] ?? "N0111",
      );

      print("🚀 [성공] 화면을 긴급 모드로 전환합니다: $imageUrl");

      // 화상 통화 로직
      if (message.data['type'] == 'VIDEO_CALL') {
        final sessionId = message.data['sessionId'];
        // 통화 프로바이더에 수신 상태 알림
        container.read(callProvider.notifier).setIncomingCall(sessionId);

        // 수신 화면(RecentEventScreen과는 다른 통화 전용 화면)으로 이동
        navigatorKey.currentState?.pushNamed('/call_screen');
      }
    }
  });

  // 알림 초기화 실행
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
            '/event_screen': (context) => const RecentEventScreen(),
          },
        );
      },
    );
  }
}
