# 영상 통화 기능 (VideoCall Feature)

OpenVidu와 Firebase Cloud Messaging을 활용한 실시간 영상 통화 기능입니다.

## 📋 목차

- [기능 소개](#기능-소개)
- [기술 스택](#기술-스택)
- [파일 구조](#파일-구조)
- [환경 설정](#환경-설정)
- [사용법](#사용법)
- [API 문서](#api-문서)
- [트러블슈팅](#트러블슈팅)

---

## 🎯 기능 소개

### 주요 기능
- ✅ 1:1 실시간 영상 통화
- ✅ 펫(디스플레이)에서 보호자에게 전화 걸기
- ✅ 보호자에서 펫(디스플레이)에게 전화 걸기
- ✅ FCM 푸시 알림을 통한 수신 전화 알림
- ✅ 마이크/카메라 토글
- ✅ 전체화면 지원
- ✅ 통화 시간 표시
- ✅ 키보드 단축키 (Enter: 수락, ESC: 거절)

### 통화 흐름
```
[발신자]                          [수신자]
   │                                 │
   ├─ 세션 생성                      │
   ├─ 토큰 발급                      │
   ├─ FCM 푸시 전송 ───────────────>│
   │                             ├─ 푸시 알림 수신
   │                             ├─ 수락/거절 선택
   │<──────────────────────────── 토큰 발급 (수락 시)
   │                                 │
   ├─────────── OpenVidu 연결 ──────>│
   │<─────────── 영상/음성 스트림 ───>│
   │                                 │
```

---

## 🛠 기술 스택

### Frontend
- **React 18** - UI 프레임워크
- **Vite** - 빌드 도구
- **Tailwind CSS** - 스타일링

### 영상 통화
- **OpenVidu Browser 2.30.0** - WebRTC 라이브러리
- **OpenVidu Server** - 미디어 서버 (백엔드)

### 푸시 알림
- **Firebase Cloud Messaging (FCM)** - 푸시 알림
- **Firebase SDK 10.x** - Firebase 클라이언트

---

## 📁 파일 구조

```
src/features/videocall/
├── constants/
│   └── callConstants.js          # 상수 정의
├── context/
│   ├── VideoCallContext.jsx      # Context 생성
│   └── VideoCallProvider.jsx     # 전역 상태 관리
├── hooks/
│   ├── useVideoCall.js           # VideoCall Hook
│   ├── useOpenVidu.js            # OpenVidu 세션 관리
│   └── useCallNotification.js   # FCM/알림 처리
├── components/
│   ├── IncomingCallOverlay.jsx   # 수신 전화 UI
│   └── VideoCallOverlay.jsx      # 통화 중 UI
└── services/
    ├── openviduApi.js            # OpenVidu API 호출
    └── fcmService.js             # FCM 토큰/메시지 관리
```

---

## ⚙️ 환경 설정

### 1. 환경 변수 설정

`.env.example`을 복사하여 `.env` 파일을 생성하세요.

```bash
cp .env.example .env
```

### 2. Firebase 설정

#### 2.1. Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 생성 또는 선택
3. **프로젝트 설정** → **일반** → **내 앱** → **웹 앱 추가**

#### 2.2. SDK 설정 복사
```bash
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789012
VITE_FIREBASE_APP_ID=1:123456789012:web:abcdef123456
```

#### 2.3. VAPID Key 생성
1. **Cloud Messaging** 탭 → **웹 푸시 인증서**
2. **키 페어 생성** 클릭
3. 생성된 키를 `.env`에 추가

```bash
VITE_FIREBASE_VAPID_KEY=your_vapid_key_here
```

### 3. 의존성 설치

```bash
npm install openvidu-browser firebase
```

### 4. App.jsx에 Provider 추가

```jsx
import { VideoCallProvider } from './features/videocall/context/VideoCallProvider';
import IncomingCallOverlay from './features/videocall/components/IncomingCallOverlay';
import VideoCallOverlay from './features/videocall/components/VideoCallOverlay';

function App() {
    return (
        <VideoCallProvider>
            <YourApp />
            <IncomingCallOverlay />
            <VideoCallOverlay />
        </VideoCallProvider>
    );
}
```

---

## 🚀 사용법

### 1. 기본 사용법

```jsx
import useVideoCall from './features/videocall/hooks/useVideoCall';

function MyComponent() {
    const { startCall, startPetCall, callState } = useVideoCall();

    const handleCallUser = async () => {
        await startCall(userId);
    };

    const handleCallGuardians = async () => {
        await startPetCall();
    };

    return (
        <div>
            <button onClick={handleCallUser}>전화 걸기</button>
            <button onClick={handleCallGuardians}>보호자 호출</button>
            <p>상태: {callState}</p>
        </div>
    );
}
```

### 2. 전체 API

```javascript
const {
    callState,      // 현재 통화 상태
    incomingCall,   // 수신 전화 정보
    localStream,    // 내 영상 스트림
    remoteStream,   // 상대방 영상 스트림
    isMicOn,        // 마이크 ON/OFF
    isCameraOn,     // 카메라 ON/OFF
    error,          // 에러 메시지
    startCall,      // 전화 걸기
    startPetCall,   // 보호자 전체 호출
    acceptCall,     // 전화 받기
    rejectCall,     // 전화 거절
    endCall,        // 통화 종료
    toggleMic,      // 마이크 토글
    toggleCamera,   // 카메라 토글
} = useVideoCall();
```

---

## 📡 API 문서

### Backend API 엔드포인트

#### 1. 세션 생성
```
POST /api/openvidu/sessions
Response: "sessionId"
```

#### 2. 연결(토큰) 생성
```
POST /api/openvidu/sessions/{sessionId}/connections
Response: "token"
```

#### 3. 사용자에게 전화
```
POST /api/openvidu/call/user
Body: { userId, sessionId }
```

#### 4. 펫의 모든 사용자에게 전화
```
POST /api/openvidu/call/users-by-pet
Body: { sessionId }
```

#### 5. FCM 토큰 등록
```
POST /api/pets/fcm-token
Body: { fcmToken }
```

---

## 🐛 트러블슈팅

### 1. "알림 권한이 차단되어 있습니다"

**해결:**
1. 주소창 왼쪽의 자물쇠/정보 아이콘 클릭
2. "알림" 항목 → "허용"으로 변경
3. 페이지 새로고침

### 2. "FCM 토큰 발급에 실패했습니다"

**해결:**
```bash
# 환경변수 확인
echo $VITE_FIREBASE_API_KEY
echo $VITE_FIREBASE_VAPID_KEY

# Service Worker 파일 확인
ls public/firebase-messaging-sw.js
```

### 3. "OpenVidu 연결 실패"

**해결:**
- 백엔드 서버 상태 확인
- 네트워크 탭에서 요청 확인
- CORS 설정 확인

---

## 📊 성능 최적화

- FCM 토큰 7일간 캐싱
- API 요청 실패 시 자동 재시도 (최대 2회)
- 메모리 누수 방지 (리스너 자동 정리)

---

## 🔒 보안

1. `.env` 파일은 Git에 절대 커밋하지 않기
2. Firebase API Key는 도메인 제한 설정
3. HTTPS 필수 (프로덕션 환경)

---

## 📝 참고 자료

- [OpenVidu 공식 문서](https://docs.openvidu.io/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [WebRTC API](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API)
