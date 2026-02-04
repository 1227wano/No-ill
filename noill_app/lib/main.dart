import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/models/event_model.dart';
import 'package:noill_app/models/pet_model.dart';
import 'package:noill_app/providers/call_privoder.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:noill_app/providers/event_provider.dart';
import 'package:noill_app/screens/auth/welcome_screen.dart';
import 'package:noill_app/screens/call/call_screen.dart';
import 'package:noill_app/services/fcm_service.dart';

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
  // 이미 초기화되었는지 확인 후 실행 [default 에러 방지]
  try {
    // 앱이 이미 실행 중이거나 Hot Restart 시 중복 호출되는 것을 방지
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase 초기화 성공");
    }
  } catch (e) {
    // 중복 에러가 나더라도 앱은 계속 실행되도록 함
    print("Firebase 초기화 건너뜀 (이미 실행 중): $e");
  }

  // 💡 [여기입니다!] 실물 기기의 새로운 토큰을 가져와 콘솔에 찍기
  String? token = await FirebaseMessaging.instance.getToken();

  print("---------------------------------------");
  print("🚀 [FCM TOKEN]: $token"); // 👈 이 값을 복사해서 Firebase 콘솔에 넣으세요!
  print("---------------------------------------");

  // Riverpod 컨테이너 생성
  final container = ProviderContainer();

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
      // 🎯 배너가 보고 있는 프로바이더와 이름을 똑같이 맞춰줍니다!
      container.read(latestAccidentImageProvider.notifier).state = imageUrl;

      print("🚀 [성공] 화면을 긴급 모드로 전환합니다: $imageUrl");

      // 화상 통화 로직
      if (message.data['type'] == 'VIDEO_CALL') {
        final sessionId = message.data['sessionId'] ?? '';
        final petId = message.data['petId'] ?? '';

        // 🎯 1. Provider에서 현재 로드된 PetModel 리스트를 가져옵니다.
        // careListProvider가 반환하는 타입이 List<PetModel>이라고 가정합니다.
        final List<PetModel> pets =
            container.read(careListProvider).value ?? [];

        // 🎯 2. 리스트에서 petId가 일치하는 모델을 찾습니다.
        final matchedPet = pets.firstWhere(
          (p) => p.petId == petId,
          orElse: () => PetModel(petId: petId, careName: "어르신"), // 못 찾을 경우 기본값
        );

        // 🎯 3. 통화 프로바이더에 수신 정보 전달 (이름 포함)
        container
            .read(callProvider.notifier)
            .setIncomingCall(
              sessionId,
              petId,
              matchedPet.careName, // PetModel에서 가져온 성함
            );

        // 4. 화상 통화 화면으로 이동
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              initialState: CallStatus.incoming,
              petId: petId,
              careName: matchedPet.careName,
            ),
          ),
        );
      }
    }
  });

  // 알림 초기화 실행
  await initializeNotification(container);

  // runApp(
  //   UncontrolledProviderScope(container: container, child: const NoIllApp()),
  // );
  runApp(const ProviderScope(child: NoIllApp()));
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
