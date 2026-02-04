import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import '../core/storage/storage_provider.dart';
import 'package:noill_app/main.dart';

// ✅ 최신 사고 이미지를 관리하는 상태 (홈 화면에서 구독)
final latestAccidentImageProvider = StateProvider<String?>((ref) => null);

final fcmServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return FcmService(dio, ref);
});

class FcmService {
  final Dio _dio;
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FcmService(this._dio, this._ref);

  /// [1. 초기화]
  Future<void> initialize() async {
    // 안드로이드 알림 채널 설정
    final channel = const AndroidNotificationChannel(
      'high_importance_channel',
      '긴급 사고 알림',
      description: '어르신의 낙상 사고 알림을 실시간으로 수신합니다.',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 알림 초기화 설정
    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => _navigateToAlarmScreen(),
    );

    // 🔔 Foreground 메시지 리스너 (앱이 켜져 있을 때)
    FirebaseMessaging.onMessage.listen((message) {
      _handleMessageLogic(message); // 상태 업데이트 및 데이터 처리
      _showNotificationPopup(message, channel); // 팝업 노출
    });

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((token) => sendTokenToServer(token));

    print('🚀 [FCM SERVICE] 초기화 완료');
  }

  /// [2. 데이터 및 상태 처리]
  void _handleMessageLogic(RemoteMessage message) {
    print("📩 푸시 데이터 도착: ${message.data}"); // 👈 데이터가 진짜 imageUrl로 오는지 확인
    // 서버 페이로드에서 이미지 URL 추출 (notification 또는 data 필드)
    final String? imageUrl =
        message.notification?.android?.imageUrl ?? message.data['imageUrl'];

    if (imageUrl != null) {
      print("📸 새 사고 이미지 수신: $imageUrl");
      // ✅ Riverpod 상태를 갱신하여 UI를 즉시 변화시킴
      _ref.read(latestAccidentImageProvider.notifier).state = imageUrl;
    }
  }

  /// [3. 알림 팝업 노출]
  Future<void> _showNotificationPopup(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    final String? imageUrl =
        notification.android?.imageUrl ?? message.data['imageUrl'];
    BigPictureStyleInformation? styleInformation;

    // 이미지가 있다면 다운로드하여 팝업에 표시
    if (imageUrl != null) {
      try {
        final filePath = await _downloadAndSaveFile(imageUrl);
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
        );
      } catch (e) {
        print('⚠️ 이미지 로드 실패: $e');
      }
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: styleInformation,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<String> _downloadAndSaveFile(String url) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/fcm_img.jpg';
    await _dio.download(url, filePath);
    return filePath;
  }

  /// [4. 클릭 리스너 및 토큰 관리]
  Future<void> setupNotificationClickListeners() async {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => _navigateToAlarmScreen(),
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _navigateToAlarmScreen();
  }

  void _navigateToAlarmScreen() =>
      navigatorKey.currentState?.pushNamed('/alarms');

  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();

      // ---------------------------------------------------------
      // 🚀 [디버그 로그] 토큰 확인용
      print("\n================ FCM TOKEN 확인 ================");
      print("TOKEN: $token");
      print("시간: ${DateTime.now()}");
      print("================================================\n");
      // ---------------------------------------------------------

      return token;
    } catch (e) {
      print('❌ [FCM] 토큰 획득 실패: $e');
      return null;
    }
  }

  Future<bool> sendTokenToServer(String token) async {
    try {
      // accessToken이 없으면 서버 등록 스킵 (로그인 전 403 방지)
      final storage = _ref.read(storageProvider);
      final accessToken = await storage.read(key: 'accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        print('⏭️ [FCM] accessToken 없음 - 서버 토큰 등록 스킵');
        return false;
      }

      await _dio.post(
        ApiConstants.registerNotification,
        data: {'token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
