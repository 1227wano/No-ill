# FCM 리팩토링 요약 문서

## 📌 변경 사항 요약

### 1️⃣ Warning 해결 (2가지)

#### auth_provider.dart - Line 43

**문제**: `accessToken.length ?? 0` - null일 수 없는 String에 대해 ?? 연산자 사용

```dart
// ❌ Before
print('AuthNotifier: tokens saved (accessToken length=${response.data!.accessToken.length ?? 0})',);

// ✅ After
print('AuthNotifier: tokens saved (accessToken length=${response.data!.accessToken.length})',);
```

#### home_screen.dart - Line 76

**문제**: `_buildDrawer` 메서드가 선언되었으나 어디에도 사용되지 않음

```dart
// ❌ Before - 76줄부터 128줄까지 사용되지 않는 _buildDrawer 메서드
Widget _buildDrawer(BuildContext context, WidgetRef ref) { ... }

// ✅ After - 메서드 완전 제거
```

---

## 🔥 FCM 코드 개선 사항

### 2️⃣ FcmService 개선

#### Before (기존 코드)

```dart
// ❌ 문제점:
// 1. 테스트/프로덕션 URL을 service에서 관리 (중복)
// 2. 토큰 전송만 가능 (수신 리스너 없음)
// 3. 에러 처리 부족
// 4. 로그 메시지 미흡

class FcmService {
  static const String _testUrl = 'http://localhost:8080';
  static const String _prodUrl = 'https://i14a301.p.ssafy.io';

  Future<bool> sendTokenToServer(String fcmToken, String jwt) async {
    // 단순히 토큰만 전송
  }
}
```

#### After (개선된 코드)

```dart
// ✅ 개선사항:
// 1. ApiConstants.baseUrl 재사용 (일관성)
// 2. 상세한 에러 핸들링 & 로깅
// 3. 토큰 갱신 리스너 추가
// 4. 포그라운드 메시지 리스너 추가
// 5. 백그라운드 메시지 지원

class FcmService {
  final Dio _dio;

  /// 토큰 가져오기
  Future<String?> getFcmToken() async { ... }

  /// 토큰 전송 (AccessToken 필수)
  Future<bool> sendTokenToServer(String fcmToken, String accessToken) async { ... }

  /// 토큰 갱신 시 자동 전송
  void listenToTokenRefresh(String accessToken) { ... }

  /// 앱 실행 중 메시지 수신
  void listenToForegroundMessages() { ... }

  /// 앱 완전 종료 후 메시지 확인
  Future<RemoteMessage?> getInitialMessage() async { ... }
}
```

---

### 3️⃣ AuthProvider 개선

#### Before (기존 코드)

```dart
// ❌ 문제점:
// 1. 로그인 후 FCM 처리 안 함
// 2. 토큰 전송 로직 없음
// 3. 수동으로 별도 처리 필요

Future<bool> login(String id, String password) async {
  // 로그인만 처리
  return true;
}
```

#### After (개선된 코드)

```dart
// ✅ 개선사항:
// 1. 로그인 후 자동으로 FCM 토큰 전송
// 2. 토큰 갱신 리스너 자동 등록
// 3. 메시지 리스너 자동 등록
// 4. 상세한 에러 처리

Future<bool> login(String id, String password) async {
  state = const AsyncValue.loading();
  try {
    final response = await ref.read(authServiceProvider).login(id, password);

    if (response.success && response.data != null) {
      // 토큰 저장
      await _storage.write(key: 'accessToken', value: response.data!.accessToken);
      state = AsyncValue.data(response.data);

      // 🔥 NEW: 로그인 후 자동으로 FCM 처리
      await _handlePostLoginFcm(response.data!.accessToken);

      return true;
    }
  } catch (e, stack) {
    state = AsyncValue.error(e, stack);
    return false;
  }
}

/// 로그인 후 FCM 처리 (새로운 함수)
Future<void> _handlePostLoginFcm(String accessToken) async {
  try {
    final fcmService = ref.read(fcmServiceProvider);

    // 1. 토큰 가져오기
    final fcmToken = await fcmService.getFcmToken();

    if (fcmToken != null) {
      // 2. 토큰 전송
      final success = await fcmService.sendTokenToServer(fcmToken, accessToken);

      if (success) {
        // 3. 리스너 등록
        fcmService.listenToTokenRefresh(accessToken);
        fcmService.listenToForegroundMessages();
      }
    }
  } catch (e) {
    print('❌ FCM 처리 오류: $e');
  }
}
```

---

### 4️⃣ main.dart 개선

#### Before (기존 코드)

```dart
// ❌ 문제점:
// 1. 백그라운드 메시지 핸들러 없음
// 2. 권한 요청 후 처리만 함
// 3. 로그 정보 미흡

Future<void> _initializeNotification() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  String? fcmToken = await messaging.getToken(...);
  print('🚀 [FCM TOKEN] : $fcmToken');
}
```

#### After (개선된 코드)

```dart
// ✅ 개선사항:
// 1. 권한 요청 후 상태 확인
// 2. 백그라운드 메시지 핸들러 등록
// 3. 상세한 권한 상태 로깅
// 4. AuthProvider에서 실제 처리 (분리)

Future<void> _initializeNotification() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 권한 요청 및 상태 확인
  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ [FCM] 알림 권한 승인');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ [FCM] 임시 권한만 승인');
  } else {
    print('❌ [FCM] 알림 권한 거부');
    return;
  }

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// 백그라운드 메시지 처리 (새로운 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 [FCM] 백그라운드 메시지 수신: ${message.notification?.title}');
}
```

---

## 📊 플로우 다이어그램

### Before (기존 흐름)

```
[App Launch]
  ↓
[초기화] - 권한 요청 (토큰 미전송)
  ↓
[로그인] - FCM 처리 없음 ❌
  ↓
[수동으로] - 별도 함수 호출 필요 ❌
```

### After (개선된 흐름)

```
[App Launch]
  ↓
[초기화]
  ├─ 권한 요청
  └─ 백그라운드 핸들러 등록
  ↓
[로그인]
  ├─ 토큰 저장
  └─ FCM 처리 자동 실행 ✅
      ├─ 토큰 전송
      ├─ 토큰 갱신 리스너 등록
      └─ 메시지 리스너 등록
  ↓
[메시지 수신]
  ├─ 포그라운드: listenToForegroundMessages()
  ├─ 백그라운드: _firebaseMessagingBackgroundHandler()
  └─ 초기화: getInitialMessage()
```

---

## 🧪 테스트용 유틸리티

새 파일 생성: `lib/services/fcm_debug_service.dart`

```dart
class FcmDebugService {
  // 1. AccessToken 확인
  static Future<String?> getStoredAccessToken() async { ... }

  // 2. FCM 토큰 확인
  static Future<void> printCurrentFcmToken() async { ... }

  // 3. 저장소 전체 확인
  static Future<void> printAllStoredKeys() async { ... }

  // 4. 종합 진단
  static Future<void> diagnoseLoginStatus() async { ... }

  // 5. 토큰 초기화 (테스트용)
  static Future<void> clearAllTokens() async { ... }
}
```

### 사용 예시

```dart
// 로그인 화면에서 테스트 버튼 추가
TextButton(
  onPressed: () {
    FcmDebugService.diagnoseLoginStatus();
  },
  child: const Text('FCM 진단'),
),
```

---

## ✅ 체크리스트

### 파일 변경

- [x] `lib/providers/auth_provider.dart` - FCM 자동 처리 추가
- [x] `lib/services/fcm_service.dart` - 상세 에러 처리 및 리스너 추가
- [x] `lib/main.dart` - 백그라운드 핸들러 추가
- [x] `lib/services/fcm_debug_service.dart` - 디버깅 유틸리티 생성

### Warning 제거

- [x] `auth_provider.dart` line 43 - null 체크 연산자 제거
- [x] `home_screen.dart` line 76 - 사용하지 않는 메서드 제거

### 로그 개선

- [x] FCM 각 단계별 명확한 로그 추가
- [x] 에러 메시지 상세화
- [x] 진행 상황 시각적 표시 (✅, ❌, 🚀 등)

---

## 🎯 이점

| 항목            | Before  | After   |
| --------------- | ------- | ------- |
| 자동 토큰 전송  | ❌ 수동 | ✅ 자동 |
| 토큰 갱신 처리  | ❌ 없음 | ✅ 자동 |
| 메시지 수신     | ❌ 없음 | ✅ 지원 |
| 백그라운드 처리 | ❌ 없음 | ✅ 지원 |
| 에러 처리       | ⚠️ 미흡 | ✅ 상세 |
| 로깅            | ⚠️ 기본 | ✅ 상세 |
| 테스트 도구     | ❌ 없음 | ✅ 제공 |

---

## 📚 추가 참고

- [FCM 토큰 테스트 가이드](./FCM_TOKEN_TEST_GUIDE.md)
- [FcmService API 문서](./lib/services/fcm_service.dart)
- [FcmDebugService 사용법](./lib/services/fcm_debug_service.dart)
