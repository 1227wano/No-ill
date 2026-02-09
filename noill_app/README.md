# No-Ill 모바일 앱 (noill_app)

노인 케어 IoT 플랫폼의 공식 모바일 애플리케이션입니다. 보호자용 Flutter 앱으로 펫 모니터링, 일정 관리, 영상 통화 등의 기능을 제공합니다.

## 📋 목차

- [기능](#기능)
- [기술 스택](#기술-스택)
- [개발 환경 설정](#개발-환경-설정)
- [설치 및 실행](#설치-및-실행)
- [프로젝트 구조](#프로젝트-구조)

---

## ✨ 기능

| 기능 | 설명 |
|------|------|
| 🔐 **인증** | 로그인/로그아웃, 토큰 기반 인증 |
| 👴 **펫 모니터링** | 펫(디스플레이) 상태 조회, 실시간 위치 추적 |
| 📞 **영상 통화** | OpenVidu를 통한 1:1 실시간 영상 통화 |
| 📲 **푸시 알림** | Firebase Cloud Messaging, 로컬 알림 |
| 📅 **일정 관리** | 펫의 일정 조회/추가/수정/삭제 |
| 🚨 **낙상 감지** | 실시간 낙상 알림, 자동 알림 |
| 💬 **메시지** | 펫과의 메시지 송수신 |
| 🌤️ **대시보드** | 펫 상태, 날씨, 건강 정보 한눈에 보기 |

---

## 🛠 기술 스택

**Framework**: Flutter 3.10.7, Dart
**상태 관리**: Riverpod 3.2.0
**네트워크**: Dio 5.9.0, HTTP 1.1.0
**영상 통화**: OpenVidu Flutter 0.0.15, Flutter WebRTC 1.2.0
**로컬 저장소**: Flutter Secure Storage 10.0.0
**푸시 알림**: Firebase Messaging 16.1.1, Local Notifications 20.0.0
**UI**: Flutter ScreenUtil 5.9.3, Cached Network Image 3.4.1

---

## 🚀 개발 환경 설정

### 1. 필수 요구사항
- Flutter SDK 3.10.7 이상
- Dart 3.10.7 이상
- Android Studio 또는 Xcode
- Android SDK 21 이상 (Android) 또는 iOS 12 이상 (iOS)

### 2. 환경 변수 설정

`.env` 파일 생성:
```bash
API_BASE_URL=http://your-api-server.com
OPENVIDU_URL=http://your-openvidu-server.com
FIREBASE_PROJECT_ID=your-project-id
```

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. 코드 생성 (Riverpod)
```bash
dart run build_runner build
```

### 5. Firebase 설정

#### Android
1. Firebase Console에서 Android 앱 추가
2. `google-services.json` 다운로드
3. `android/app/` 디렉토리에 배치

#### iOS
1. Firebase Console에서 iOS 앱 추가
2. `GoogleService-Info.plist` 다운로드
3. Xcode에서 Runner.xcodeproj에 추가

---

## 🚀 설치 및 실행

### 1. 개발 모드 실행

```bash
# 전체 빌드
flutter run

# 특정 기기에서 실행
flutter run -d <device_id>

# Hot reload 활성화
flutter run -v
```

### 2. 빌드

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

### 3. 코드 검사
```bash
flutter analyze
```

### 4. 포맷팅
```bash
dart format .
```

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                 # 애플리케이션 진입점
├── core/                     # 핵심 설정
│   ├── config/              # 앱 설정 (Firebase, API 등)
│   ├── constants/           # 상수, 문자열
│   ├── theme/               # 테마, 스타일
│   └── utils/               # 유틸리티 함수
├── models/                   # 데이터 모델
│   ├── user_model.dart
│   ├── pet_model.dart
│   ├── schedule_model.dart
│   └── ...
├── providers/                # Riverpod State Management
│   ├── auth_provider.dart
│   ├── pet_provider.dart
│   ├── schedule_provider.dart
│   └── ...
├── services/                 # API, Firebase 서비스
│   ├── api/                 # REST API 클라이언트
│   ├── firebase/            # Firebase 서비스
│   └── notification/        # 알림 서비스
├── screens/                  # 화면 (페이지)
│   ├── auth/                # 로그인, 회원가입
│   ├── home/                # 홈 화면
│   ├── pet_detail/          # 펫 상세 정보
│   ├── schedule/            # 일정 관리
│   ├── video_call/          # 영상 통화
│   └── ...
└── widgets/                  # 재사용 가능한 UI 컴포넌트
    ├── common/              # 공통 위젯
    └── ...
```

---

## 🔌 주요 서비스

### 인증 (Auth)
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
// 로그인, 로그아웃, 토큰 관리
```

### 펫 관리 (Pet)
```dart
final petProvider = FutureProvider<List<Pet>>(...);
final selectedPetProvider = StateProvider<Pet?>(...);
// 펫 목록 조회, 펫 선택, 상태 모니터링
```

### 일정 (Schedule)
```dart
final scheduleProvider = FutureProvider<List<Schedule>>(...);
// 일정 조회, 추가, 수정, 삭제
```

### 영상 통화 (Video Call)
```dart
final videoCallProvider = StateNotifierProvider<VideoCallNotifier, ...>(...);
// 통화 시작, 종료, 스트림 관리
```

---

## 📡 Backend API

### 인증
```
POST /api/auth/login         # 로그인
POST /api/auth/refresh       # 토큰 갱신
POST /api/auth/logout        # 로그아웃
```

### 펫
```
GET /api/pets                # 펫 목록
GET /api/pets/{id}           # 펫 상세
PUT /api/pets/{id}           # 펫 정보 수정
GET /api/pets/{id}/status    # 펫 상태 조회
```

### 일정
```
GET /api/schedules           # 일정 조회
POST /api/schedules          # 일정 추가
PUT /api/schedules/{id}      # 일정 수정
DELETE /api/schedules/{id}   # 일정 삭제
```

### 영상 통화
```
POST /api/openvidu/sessions                    # 세션 생성
POST /api/openvidu/sessions/{id}/connections   # 토큰 발급
POST /api/pets/{id}/call                       # 펫 호출
```

### 알림
```
POST /api/notifications      # 알림 조회
```

---

## 🔐 보안

- 토큰은 Flutter Secure Storage에 저장
- `.env` 파일에 민감한 정보 저장 (Git 제외)
- Firebase API Key는 Google Cloud Console에서 제한 설정
- HTTPS 필수 (프로덕션)

---

## 📱 지원 플랫폼

- **Android**: 5.0 (API 21) 이상
- **iOS**: 12.0 이상

---

## 🐛 트러블슈팅

| 문제 | 해결 방법 |
|------|---------|
| gradle 빌드 실패 | `flutter clean` 후 다시 빌드 |
| Podfile 오류 (iOS) | `cd ios && pod install --repo-update` |
| Firebase 연결 실패 | google-services.json 또는 GoogleService-Info.plist 확인 |
| 영상 통화 권한 오류 | 앱 권한 설정에서 카메라/마이크 허용 |
| Riverpod 코드 생성 안됨 | `dart run build_runner build --delete-conflicting-outputs` |

---

## 📚 참고 자료

- [Flutter 공식 문서](https://flutter.dev)
- [Riverpod 문서](https://riverpod.dev)
- [OpenVidu Flutter](https://docs.openvidu.io/)
- [Firebase Flutter](https://firebase.flutter.dev)
