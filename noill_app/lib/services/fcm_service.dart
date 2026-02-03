import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import 'package:noill_app/main.dart'; // navigatorKey 사용을 위함

// ✅ 사고 발생 시 최신 이미지를 UI에서 즉시 사용하기 위한 프로바이더
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

  /// [1. 초기화] 알림 채널 설정 및 리스너 등록
  Future<void> initialize() async {
    // ✅ AndroidNotificationChannel은 const가 될 수 없습니다. final로 변경하세요.
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
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

    // ✅ 'const' 키워드를 제거하고 iOS 설정을 포함하세요.
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(), // 👈 여기서 에러가 난다면 const를 지워야 합니다.
      ),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _navigateToAlarmScreen();
      },
    );
    print('🚀 [FCM SERVICE] 초기화 완료');
  }

  /// [2. 데이터 처리] 상태 업데이트 및 데이터 파싱
  void _handleMessageLogic(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // ✅ 서버의 .setImage() 경로에서 이미지 URL 추출
    final String? imageUrl =
        notification?.android?.imageUrl ??
        notification?.apple?.imageUrl ??
        data['imageUrl'];

    // ✅ 전역 상태 업데이트 (홈 화면 실시간 반영용)
    if (imageUrl != null) {
      _ref.read(latestAccidentImageProvider.notifier).state = imageUrl;
    }

    if (data.isNotEmpty) {
      try {
        // EventModel 생성 (서버 키값 확인: eventNo, petId 등)
        final newEvent = EventModel(
          eventNo: int.parse(data['eventNo']?.toString() ?? '0'),
          eventTime: DateTime.parse(
            data['eventTime']?.toString() ?? DateTime.now().toIso8601String(),
          ),
          petId: data['petId']?.toString() ?? '',
          imageUrl: imageUrl ?? '',
        );

        // 필요한 경우 특정 화면으로 자동 이동 (선택 사항)
        // navigatorKey.currentState?.pushNamed('/event_screen', arguments: newEvent);
      } catch (e) {
        print('❌ [FCM] 데이터 파싱 에러: $e');
      }
    }
  }

  /// [3. 알림 팝업 노출] BigPictureStyle 적용 (사진 포함 알림)
  Future<void> _showNotificationPopup(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    final String title = notification.title ?? '⚠️ 사고 발생';
    final String body = notification.body ?? '즉시 확인이 필요합니다.';

    // ✅ 이미지 URL 추출
    final String? imageUrl =
        notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? styleInformation;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String filePath = await _downloadAndSaveFile(imageUrl);
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: title,
          summaryText: body,
        );
      } catch (e) {
        print('⚠️ 이미지 다운로드 실패, 일반 알림으로 대체: $e');
      }
    }

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.hashCode, // 1. ID
      title: title, // 2. Title
      body: body, // 3. Body
      notificationDetails: NotificationDetails(
        // 4. Details
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description, // ✅ 명시적으로 추가 권장
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: styleInformation,
        ),
        // iOS 대응을 위해 DarwinNotificationDetails() 추가 (선택사항이나 권장)
        iOS: const DarwinNotificationDetails(),
      ),
      payload: imageUrl, // 5. Payload
    );
  }

  /// [4. 이미지 다운로드 헬퍼]
  Future<String> _downloadAndSaveFile(String url) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/fcm_curr_img.jpg';

    // Dio를 사용하여 HTTP 이미지 다운로드 (cleartext 설정 필요)
    await _dio.download(url, filePath);
    return filePath;
  }

  /// [5. 클릭 리스너 설정] 앱 종료/백그라운드 상태에서 클릭 시
  Future<void> setupNotificationClickListeners() async {
    // 백그라운드에서 알림 클릭 시
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateToAlarmScreen();
    });

    // 종료 상태에서 알림 클릭 시
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateToAlarmScreen();
    }
  }

  void _navigateToAlarmScreen() {
    print("🔔 알림 클릭: 알림 센터로 이동합니다.");
    navigatorKey.currentState?.pushNamed('/alarms');
  }

  /// [4. FCM 토큰 관리]
  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('🔥 [FCM Token]: $token');
        // ✅ 토큰을 얻자마자 서버로 전송하는 로직을 호출하는 것이 좋습니다.
        await sendTokenToServer(token);
      }
      return token;
    } catch (e) {
      print('❌ [FCM] 토큰 획득 실패: $e');
      return null;
    }
  }

  // ✅ 누락되었던 서버 전송 메서드입니다.
  Future<bool> sendTokenToServer(String fcmToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerNotification, // 서버의 토큰 등록 API 엔드포인트
        data: {'token': fcmToken},
      );
      print('✅ [FCM] 서버에 토큰 등록 성공');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ [FCM] 서버 토큰 등록 실패: $e');
      return false;
    }
  }
}

/// [부록] 백그라운드 전용 핸들러 (main.dart 외부에서 사용)
// ✅ 클래스 내부 맨 아래에 static 메서드로 정의합니다.
@pragma('vm:entry-point')
Future<void> showNotificationBackground(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final String title = notification.title ?? '⚠️ 사고 발생';
  final String body = notification.body ?? '즉시 확인이 필요합니다.';
  final String? imageUrl =
      notification.android?.imageUrl ?? notification.apple?.imageUrl;

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // 백그라운드 전용 채널 설정
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    '긴급 사고 알림',
    importance: Importance.max,
  );

  await localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch.hashCode,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    payload: imageUrl,
  );
  print('✅ [FCM] 백그라운드 알림 표시 완료');
}
