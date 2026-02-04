import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/models/pet_model.dart';
import 'package:noill_app/models/call_state.dart';
import 'package:noill_app/providers/call_privoder.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:noill_app/screens/accident/event_detail_screen.dart';
import 'package:noill_app/screens/auth/welcome_screen.dart';
import 'package:noill_app/screens/call/call_screen.dart';
import 'package:noill_app/services/fcm_service.dart';

import 'firebase_options.dart';
import 'package:noill_app/core/theme/app_theme.dart';

// ✅ 화면 및 서비스 임포트
import 'screens/main_screen.dart';
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

  // main.dart의 onMessage 리스너 부분
  // main.dart의 리스너 부분
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 신호가 도착하긴 했습니다!");

    // 화상 통화 FCM (data-only 메시지)
    if (message.data['type'] == 'VIDEO_CALL') {
      final sessionId = message.data['sessionId'] ?? '';
      final petId = message.data['petId'] ?? '';

      // Provider에서 현재 로드된 PetModel 리스트를 가져옵니다.
      final List<PetModel> pets =
          container.read(careListProvider).value ?? [];

      // 리스트에서 petId가 일치하는 모델을 찾습니다.
      final matchedPet = pets.firstWhere(
        (p) => p.petId == petId,
        orElse: () => PetModel(petId: petId, careName: "어르신"),
      );

      // 통화 프로바이더에 수신 정보 전달 (이름 포함)
      container
          .read(callProvider.notifier)
          .setIncomingCall(
            sessionId,
            petId,
            matchedPet.careName,
          );

      // 화상 통화 화면으로 이동
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            initialState: CallStatus.incoming,
            petId: petId,
            careName: matchedPet.careName,
          ),
        ),
      );
      return;
    }

    // 사고 알림 FCM (이미지 포함)
    String? imageUrl =
        message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

    if (imageUrl != null) {
      container.read(latestAccidentImageProvider.notifier).state = imageUrl;
      print("🚀 [성공] 화면을 긴급 모드로 전환합니다: $imageUrl");
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(
    (msg) => _handleNotificationClick(msg, container),
  );

  // 🎯 3. [Terminated] 앱이 완전히 꺼져 있을 때 알림을 눌러 앱을 켠 경우 (추가 필요!)
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      // 앱이 완전히 켜질 때까지 약간의 지연을 주어 내비게이터가 준비되길 기다립니다.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(message, container);
      });
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

      await fcmLogic.service.sendTokenToServer(token);
      await fcmLogic.service.initialize();
      print('✅ [FCM] 초기화 및 토큰 저장 완료');
    }
  } catch (e) {
    print('❌ [FCM] 초기화 에러: $e');
  }
}

// push 알람 눌러서 event 화면으로 이동하는 로직

// 1. 클릭 핸들러 (Background/Terminated 공통)
void _handleNotificationClick(
  RemoteMessage message,
  ProviderContainer container,
) {
  final data = message.data;

  // 1. 데이터 추출 (null 방지 처리)
  final String petId = data['petId'] ?? '';
  final String title =
      data['title'] ?? message.notification?.title ?? '낙상 감지 알림';
  final String body =
      data['body'] ?? message.notification?.body ?? '어르신의 상태를 확인해주세요.';
  final String? imageUrl = data['imageUrl'];

  // 2. 어르신 리스트에서 해당 어르신 찾기
  final List<PetModel> pets = container.read(careListProvider).value ?? [];

  // 타입을 PetModel로 명시하여 빨간 줄 방지
  final PetModel matchedPet = pets.firstWhere(
    (p) => p.petId == petId,
    orElse: () => PetModel(petId: petId, careName: "어르신"),
  );

  // 3. 화면 이동 (이 부분이 질문하신 구간!)
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => EventDetailScreen(
        title: title, // 👈 '변수이름: 값' 형태로 작성
        body: body, // 👈 '변수이름: 값' 형태로 작성
        pet: matchedPet, // 👈 위에서 찾은 PetModel 객체 전달
        imageUrl: imageUrl, // 👈 이미지 URL 전달 (null 가능)
      ),
    ),
  );
}

// 2. main() 함수 내 리스너 등록
// FirebaseMessaging.onMessageOpenedApp.listen((msg) => _handleNotificationClick(msg, container));

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
            '/event_screen': (context) => const RecentEventScreen(),
          },
        );
      },
    );
  }
}
