import 'dart:io';
// kIsWeb 사용을 위함 (웹에서는 FCM 지원 안됨)
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/event_models.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import 'package:noill_app/main.dart';

// ✅ 최신 사고 이미지 URL을 저장하는 전역 상태
final latestAccidentImageProvider = StateProvider<String?>((ref) => null);

final fcmServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return FcmService(dio, ref);
});

class FcmService {
  final Dio _dio;
  final Ref _ref;

  FcmService(this._dio, this._ref);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// [1. 초기화] 채널 설정 및 수신 리스너 등록
  Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
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

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // 리스너 하나로 통합
    FirebaseMessaging.onMessage.listen((message) {
      print('📩 [FCM] 포그라운드 수신: ${message.data}');
      _handleMessage(message); // 상태 업데이트 및 로직 처리
      _showNotification(message, channel); // 알림 팝업 띄우기
    });

    print('🚀 [FCM SERVICE] 초기화 완료');
  }

  void _handleMessage(RemoteMessage message) {
    print('=============================================');
    print('📩 [FCM RAW DATA CHECK]');
    print('알림 제목: ${message.notification?.title}');
    print('알림 내용: ${message.notification?.body}');
    print('전달된 데이터(Payload): ${message.data}'); // 👈 여기서 모든 키-값을 볼 수 있습니다.
    print('=============================================');
    final data = message.data;
    if (data.isNotEmpty) {
      // ✅ 오류 해결: EventModel 생성자 규격에 맞춤
      final newEvent = EventModel(
        eventNo: int.parse(
          data['eventNo'] ?? '0',
        ), // 서버 키값 확인 필요 (event_no vs eventNo)
        eventTime: DateTime.parse(
          data['eventTime'] ?? DateTime.now().toIso8601String(),
        ),
        petId: data['petId'] ?? '',
        imageUrl: data['imageUrl'] ?? '', // 푸시 데이터의 이미지 키값에 맞춤
      );

      navigatorKey.currentState?.pushNamed(
        '/event_screen',
        arguments: newEvent,
      );
    }
  }

  /// [2. 알림 표시 로직] 사진 다운로드 및 스타일 적용
  Future<void> _showNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    final notification = message.notification;
    if (notification == null) return; // null 체크

    final String? imageUrl = message.data['file'];
    final String title = notification.title ?? '⚠️ 사고 발생';
    final String body = notification.body ?? '즉시 확인이 필요합니다.';

    BigPictureStyleInformation? style;

    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // 🖼️ 사진이 있는 경우: 다운로드 후 스타일 입히기
        final String filePath = await _downloadAndSaveFile(
          imageUrl,
          'fcm_image_${DateTime.now().millisecondsSinceEpoch}',
        );

        style = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: false, // 확장했을 때도 아이콘 표시
        );
      }
    } catch (e) {
      print('❌ [FCM] 이미지 다운로드 중 에러: $e');
      // 이미지 로드 실패해도 알림은 표시
    }

    try {
      // 실제 상단 팝업 띄우기
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: style, // 👈 사진 스타일 적용!
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: imageUrl,
      );
      print('✅ [FCM] 알림 표시 완료 - 이미지: ${style != null ? '포함' : '없음'}');
    } catch (e) {
      print('❌ [FCM] 알림 표시 중 에러: $e');
    }
  }

  /// [3. 이미지 다운로드 헬퍼]
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName.jpg';

      // Dio를 사용해 더 안정적으로 다운로드
      await _dio.download(url, filePath);

      final File file = File(filePath);
      if (await file.exists()) {
        print('✅ 이미지 다운로드 완료: $filePath');
        return filePath;
      } else {
        throw Exception('파일 저장 실패');
      }
    } catch (e) {
      print('❌ 이미지 다운로드 실패: $e');
      rethrow;
    }
  }

  /// [4. FCM 토큰 관리]
  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) print('🔥 [FCM Token]: $token');
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendTokenToServer(String fcmToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerNotification,
        data: {'token': fcmToken},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // [5. 포그라운드 메시지 리스너 등록]
  void listenToForegroundMessages(AndroidNotificationChannel channel) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 [FCM] 포그라운드 메시지 수신: ${message.messageId}');
      _showNotification(message, channel);
    });
  }

  /// [6. 백그라운드 메시지 처리용 정적 메서드]
  static Future<void> showNotificationBackground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final String? imageUrl = message.data['file'];
    final String title = notification.title ?? '⚠️ 사고 발생';
    final String body = notification.body ?? '즉시 확인이 필요합니다.';

    // 백그라운드에서 사용할 FlutterLocalNotificationsPlugin 인스턴스
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // 채널 초기화 (필요한 경우)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      '긴급 사고 알림',
      description: '어르신의 낙상 사고 알림을 실시간으로 수신합니다.',
      importance: Importance.max,
      playSound: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    try {
      // 이미지가 있으면 다운로드 시도 (백그라운드에서는 간단히 처리)
      BigPictureStyleInformation? style;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          final Directory directory = await getTemporaryDirectory();
          final String filePath =
              '${directory.path}/bg_notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(filePath).writeAsBytes(response.bodyBytes);

          style = BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            contentTitle: title,
            summaryText: body,
          );
        } catch (e) {
          print('⚠️ 백그라운드 이미지 다운로드 실패: $e');
        }
      }

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
            styleInformation: style,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: imageUrl,
      );
      print('✅ [FCM] 백그라운드 알림 표시 완료');
    } catch (e) {
      print('❌ [FCM] 백그라운드 알림 표시 실패: $e');
    }
  }

  // 앱 푸시 누르면 alarm_screen 으로 이동
  Future<void> setupNotificationClickListeners() async {
    // 1. 앱이 켜져 있는 상태(Background)에서 알림을 누른 경우
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(message);
    });

    // 2. 앱이 완전히 꺼져 있는데(Terminated) 알림을 눌러서 켠 경우
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    // 💡 context 없이도 화면 이동 가능! (type == accident 이런 조건 없이 무조건 사고로 인지)
    print("🔔 알림 클릭 감지: 사고 화면으로 점프합니다.");
    navigatorKey.currentState?.pushNamed('/alarms');
  }
}
