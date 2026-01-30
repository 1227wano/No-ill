import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_provider.dart';

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
    final String? imageUrl = message.data['file']; // 💡 서버/목업 데이터의 'file' 키 활용

    BigPictureStyleInformation? bigPictureStyle;

    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // 🖼️ 사진이 있는 경우: 다운로드 후 스타일 입히기
        final String filePath = await _downloadAndSaveFile(
          imageUrl,
          'fcm_image_${DateTime.now().millisecondsSinceEpoch}',
        );

        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: notification?.title ?? "⚠️ 사고 발생",
          summaryText: notification?.body ?? "즉시 확인이 필요합니다.",
        );
      }

      // 실제 상단 팝업 띄우기
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification?.title,
        body: notification?.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: bigPictureStyle, // 👈 사진 스타일 적용!
          ),
        ),
        payload: imageUrl,
      );
    } catch (e) {
      print('❌ [FCM] 알림 표시 중 에러: $e');
    }
  }

  /// [3. 이미지 다운로드 헬퍼]
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
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
        '/api/users/notifications',
        data: {'token': fcmToken},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
