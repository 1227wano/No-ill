// lib/services/fcm_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_provider.dart';
import '../core/network/api_constants.dart';
import '../core/storage/storage_provider.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import '../core/exceptions/app_exception.dart';
import '../providers/call_provider.dart';
import '../providers/care_provider.dart';
import '../screens/call/call_screen.dart';
import '../main.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════

/// 최신 사고 이미지 URL (홈 화면에서 구독)
class LatestAccidentImageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? value) {
    state = value;
  }
}

final latestAccidentImageProvider = NotifierProvider<LatestAccidentImageNotifier, String?>(
  () => LatestAccidentImageNotifier(),
);

/// FCM Service Provider
final fcmServiceProvider = Provider<FcmService>((ref) {
  final dio = ref.read(dioProvider);
  return FcmService(dio, ref);
});

// ═══════════════════════════════════════════════════════════════════════
// FCM Service
// ═══════════════════════════════════════════════════════════════════════

class FcmService {
  final Dio _dio;
  final Ref _ref;
  final _logger = AppLogger('FcmService');

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // 알림 채널 ID (상수화)
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = '긴급 사고 알림';
  static const String _channelDescription = '어르신의 낙상 사고 알림을 실시간으로 수신합니다.';

  FcmService(this._dio, this._ref);

  // ═══════════════════════════════════════════════════════════════════════
  // Public Methods - 초기화
  // ═══════════════════════════════════════════════════════════════════════

  /// FCM 초기화
  ///
  /// 앱 시작 시 한 번 호출됩니다.
  /// - 알림 채널 생성
  /// - 알림 권한 요청
  /// - 메시지 리스너 설정
  Future<Result<void>> initialize() async {
    try {
      _logger.info('FCM 초기화 시작');

      // Step 1: 알림 권한 요청
      final permissionGranted = await _requestNotificationPermission();
      if (!permissionGranted) {
        _logger.warning('알림 권한이 거부되었습니다');
        return Failure(AppException('알림 권한이 필요합니다'));
      }

      // Step 2: 안드로이드 알림 채널 생성
      await _createNotificationChannel();

      // Step 3: 로컬 알림 초기화
      await _initializeLocalNotifications();

      // Step 4: 메시지 리스너 설정
      _setupMessageListeners();

      // Step 5: 토큰 갱신 리스너 설정
      _setupTokenRefreshListener();

      _logger.info('FCM 초기화 완료');
      return const Success(null);

    } catch (e, stackTrace) {
      _logger.error('FCM 초기화 실패', e, stackTrace);
      return Failure(AppException('FCM 초기화 중 오류가 발생했습니다'));
    }
  }

  /// 알림 클릭 리스너 설정
  ///
  /// 앱이 백그라운드/종료 상태에서 알림 클릭 시 처리
  Future<void> setupNotificationClickListeners() async {
    try {
      _logger.info('알림 클릭 리스너 설정');

      // 앱이 백그라운드에 있을 때 알림 클릭
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _logger.info('백그라운드 알림 클릭: ${message.messageId}');
        _navigateToAlarmScreen();
      });

      // 앱이 종료된 상태에서 알림 클릭으로 시작
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.info('앱 종료 상태에서 알림 클릭: ${initialMessage.messageId}');
        _navigateToAlarmScreen();
      }

      _logger.info('알림 클릭 리스너 설정 완료');
    } catch (e, stackTrace) {
      _logger.error('알림 클릭 리스너 설정 실패', e, stackTrace);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Public Methods - 토큰 관리
  // ═══════════════════════════════════════════════════════════════════════

  /// FCM 토큰 가져오기
  Future<String?> getFcmToken() async {
    try {
      _logger.info('FCM 토큰 요청');

      final token = await _messaging.getToken();

      if (token != null) {
        _logger.info('FCM 토큰 획득 성공');
        _logger.debug('Token: ${token.substring(0, 30)}...');
      } else {
        _logger.warning('FCM 토큰이 null입니다');
      }

      return token;
    } catch (e, stackTrace) {
      _logger.error('FCM 토큰 획득 실패', e, stackTrace);
      return null;
    }
  }

  /// FCM 토큰을 서버에 등록
  Future<Result<void>> sendTokenToServer(String token) async {
    try {
      _logger.info('FCM 토큰 서버 등록 시도');

      // accessToken 확인 (로그인 전에는 등록 스킵)
      final storage = _ref.read(storageProvider);
      final accessToken = await storage.read(key: 'accessToken');

      if (accessToken == null || accessToken.isEmpty) {
        _logger.info('accessToken 없음 - 서버 등록 스킵');
        return Failure(AppException(
          '로그인이 필요합니다',
          code: 'NOT_LOGGED_IN',
        ));
      }

      // 서버에 토큰 전송
      await _dio.post(
        ApiConstants.registerNotification,
        data: {'token': token},
      );

      _logger.info('FCM 토큰 서버 등록 완료');
      return const Success(null);

    } on DioException catch (e, stackTrace) {
      _logger.error('FCM 토큰 서버 등록 실패', e, stackTrace);

      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return Failure(AuthException('인증이 만료되었습니다'));
      }

      return Failure(NetworkException('서버 연결에 실패했습니다'));
    } catch (e, stackTrace) {
      _logger.error('예상치 못한 에러', e, stackTrace);
      return Failure(AppException('토큰 등록 중 오류가 발생했습니다'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private Methods - 초기화
  // ═══════════════════════════════════════════════════════════════════════

  /// 알림 권한 요청
  Future<bool> _requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;

      _logger.info('알림 권한 상태: ${settings.authorizationStatus}');

      return isGranted;
    } catch (e, stackTrace) {
      _logger.error('알림 권한 요청 실패', e, stackTrace);
      return false;
    }
  }

  /// 안드로이드 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    try {
      if (!Platform.isAndroid) {
        _logger.debug('Android가 아니므로 채널 생성 스킵');
        return;
      }

      final channel = const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _logger.info('안드로이드 알림 채널 생성 완료');
    } catch (e, stackTrace) {
      _logger.error('알림 채널 생성 실패', e, stackTrace);
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _logger.info('로컬 알림 클릭: ${details.payload}');
          _navigateToAlarmScreen();
        },
      );

      _logger.info('로컬 알림 초기화 완료');
    } catch (e, stackTrace) {
      _logger.error('로컬 알림 초기화 실패', e, stackTrace);
    }
  }

  /// 메시지 리스너 설정
  void _setupMessageListeners() {
    // Foreground 메시지 수신 (앱이 실행 중일 때)
    FirebaseMessaging.onMessage.listen((message) {
      _logger.info('Foreground 메시지 수신: ${message.messageId}');
      _handleIncomingMessage(message);
      _showLocalNotification(message);
    });

    _logger.info('메시지 리스너 설정 완료');
  }

  /// 토큰 갱신 리스너 설정
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((token) {
      _logger.info('FCM 토큰 갱신됨');
      sendTokenToServer(token);
    });

    _logger.info('토큰 갱신 리스너 설정 완료');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private Methods - 메시지 처리
  // ═══════════════════════════════════════════════════════════════════════

  /// 수신된 메시지 처리 (데이터 추출 및 상태 업데이트)
  void _handleIncomingMessage(RemoteMessage message) {
    try {
      _logger.info('메시지 데이터 처리 시작');
      _logger.debug('Data: ${message.data}');
      _logger.debug('Notification: ${message.notification?.toMap()}');

      final messageType = message.data['type'] as String?;

      // VIDEO_CALL 타입 처리
      if (messageType == 'VIDEO_CALL') {
        _handleVideoCallMessage(message);
        return;
      }

      // 사고 이미지 URL 추출
      final imageUrl = _extractImageUrl(message);

      if (imageUrl != null) {
        _logger.info('사고 이미지 URL 수신: $imageUrl');

        // 상태 업데이트 (UI 자동 갱신)
        _ref.read(latestAccidentImageProvider.notifier).update(imageUrl);
      } else {
        _logger.debug('이미지 URL 없음');
      }

    } catch (e, stackTrace) {
      _logger.error('메시지 처리 실패', e, stackTrace);
    }
  }

  /// 영상통화 FCM 메시지 처리
  void _handleVideoCallMessage(RemoteMessage message) {
    try {
      final sessionId = message.data['sessionId'] as String?;

      _logger.info('영상통화 수신: sessionId=$sessionId');

      if (sessionId == null || sessionId.isEmpty) {
        _logger.error('sessionId가 없어 통화를 수락할 수 없습니다');
        return;
      }

      // FCM 데이터에 petId/careName이 없으면 현재 선택된 어르신 정보 사용
      final selectedPet = _ref.read(selectedPetProvider);
      final petId = message.data['petId'] as String? ?? selectedPet?.petId ?? '';
      final careName = message.data['careName'] as String? ?? selectedPet?.petName ?? '어르신';

      _logger.info('통화 정보: petId=$petId, careName=$careName');

      // CallProvider에 수신 전화 정보 설정
      _ref.read(callProvider.notifier).setIncomingCall(
        sessionId,
        petId,
        careName,
      );

      // 통화 화면으로 이동
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            petId: petId,
            careName: careName,
            isIncoming: true,
          ),
        ),
      );

      _logger.info('통화 화면으로 이동 완료');
    } catch (e, stackTrace) {
      _logger.error('영상통화 메시지 처리 실패', e, stackTrace);
    }
  }

  /// 메시지에서 이미지 URL 추출
  String? _extractImageUrl(RemoteMessage message) {
    // 1. Android notification 이미지
    final androidImage = message.notification?.android?.imageUrl;
    if (androidImage != null) return androidImage;

    // 2. Data 필드의 imageUrl
    final dataImage = message.data['imageUrl'] as String?;
    if (dataImage != null) return dataImage;

    // 3. Data 필드의 image
    final dataImage2 = message.data['image'] as String?;
    if (dataImage2 != null) return dataImage2;

    return null;
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) {
        _logger.debug('notification이 null이므로 팝업 스킵');
        return;
      }

      _logger.info('로컬 알림 표시: ${notification.title}');

      // 이미지 스타일 생성 (있는 경우)
      final styleInformation = await _createBigPictureStyle(message);

      // 알림 표시
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: styleInformation,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      _logger.info('로컬 알림 표시 완료');
    } catch (e, stackTrace) {
      _logger.error('로컬 알림 표시 실패', e, stackTrace);
    }
  }

  /// BigPicture 스타일 생성 (이미지 알림)
  Future<BigPictureStyleInformation?> _createBigPictureStyle(
      RemoteMessage message,
      ) async {
    try {
      final imageUrl = _extractImageUrl(message);
      if (imageUrl == null) return null;

      _logger.info('이미지 다운로드 시도: $imageUrl');

      // 이미지 다운로드
      final filePath = await _downloadImage(imageUrl);

      _logger.info('이미지 다운로드 완료: $filePath');

      return BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        largeIcon: FilePathAndroidBitmap(filePath),
        contentTitle: message.notification?.title,
        summaryText: message.notification?.body,
      );
    } catch (e, stackTrace) {
      _logger.error('BigPicture 스타일 생성 실패', e, stackTrace);
      return null;
    }
  }

  /// 이미지 다운로드 및 저장
  Future<String> _downloadImage(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/fcm_img_$timestamp.jpg';

      await _dio.download(
        url,
        filePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return filePath;
    } catch (e, stackTrace) {
      _logger.error('이미지 다운로드 실패', e, stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Private Methods - 네비게이션
  // ═══════════════════════════════════════════════════════════════════════

  /// 사고 목록 화면으로 이동
  void _navigateToAlarmScreen() {
    try {
      _logger.info('사고 목록 화면으로 이동');
      navigatorKey.currentState?.pushNamed('/alarms');
    } catch (e, stackTrace) {
      _logger.error('화면 이동 실패', e, stackTrace);
    }
  }
}
