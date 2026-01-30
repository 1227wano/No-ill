import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';

final fcmServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return FcmService(dio);
});

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Dio _dio;

  FcmService(this._dio);

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

    // 포그라운드 리스너 연결
    FirebaseMessaging.onMessage.listen(
      (message) => _showNotification(message, channel),
    );
    print('🚀 [FCM SERVICE] 초기화 완료');
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
}
