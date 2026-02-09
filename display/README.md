# Display 애플리케이션

노인 케어 IoT 플랫폼을 위한 디스플레이 웹 애플리케이션입니다.

## 📋 목차

- [기능](#기능)
- [기술 스택](#기술-스택)
- [설치 및 실행](#설치-및-실행)
- [환경 설정](#환경-설정)
- [사용법](#사용법)
- [프로젝트 구조](#프로젝트-구조)

---

## ✨ 기능

| 기능 | 설명 |
|------|------|
| 🔐 **인증** | JWT 기반 로그인/로그아웃 |
| 📞 **영상 통화** | OpenVidu를 통한 1:1 실시간 영상 통화, FCM 푸시 알림 |
| 🚨 **낙상 감지** | WebSocket 실시간 낙상 감지, 자동 알림 |
| 📅 **일정 관리** | 일정 조회/추가/수정/삭제 |
| 🌤️ **날씨** | 실시간 날씨 정보 |
| 🎮 **미니게임** | 메모리 게임 (기억력 운동) |
| 💤 **자동 화면 보호** | 유휴 시간 감지, 아이들 화면 전환 |

---

## 🛠 기술 스택

**Frontend**: React 19, React Router 7, Vite 7, Tailwind CSS
**영상 통화**: OpenVidu Browser 2.32.1
**서버 통신**: Axios, Firebase SDK 12.8.0
**테스팅**: Vitest, React Testing Library

---

## 🚀 설치 및 실행

### 1. 설치
```bash
npm install
```

### 2. 개발 서버 실행
```bash
npm run dev
# http://localhost:5173에서 실행
```

### 3. 프로덕션 빌드
```bash
npm run build
```

### 4. 테스트
```bash
npm run test              # 단일 실행
npm run test:watch       # 감시 모드
npm run test:coverage    # 커버리지
```

### 5. 코드 검사
```bash
npm run lint
```

---

## ⚙️ 환경 설정

`.env` 파일 생성:

```bash
# API
VITE_API_BASE_URL=http://localhost:8080

# Firebase
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789012
VITE_FIREBASE_APP_ID=1:123456789012:web:abcdef123456
VITE_FIREBASE_VAPID_KEY=your_vapid_key

# OpenVidu
VITE_OPENVIDU_URL=http://localhost:4443
VITE_OPENVIDU_SECRET=your_secret
```

### Firebase 설정
1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. 웹 앱 설정값을 `.env`에 복사
3. Cloud Messaging > 웹 푸시 인증서에서 VAPID Key 생성
4. `public/firebase-messaging-sw.js` 파일 배치

---

## 🎯 사용법

### 인증
```jsx
import { useAuth } from './features/auth/hooks/useAuth';

const { login, logout, user } = useAuth();
```

### 영상 통화
```jsx
import useVideoCall from './features/videocall/hooks/useVideoCall';

const { startCall, endCall, toggleMic, toggleCamera } = useVideoCall();
```

### 일정 관리
```jsx
import useSchedule from './features/schedule/hooks/useSchedule';

const { schedules, addSchedule, deleteSchedule } = useSchedule();
```

### 낙상 감지
```jsx
import useFallAlert from './features/fall/hooks/useFallAlert';

const { fallAlert, dismissAlert } = useFallAlert();
```

### 날씨
```jsx
import useWeather from './features/weather/hooks/useWeather';

const { weather, loading, error } = useWeather();
```

---

## 📁 프로젝트 구조

```
src/
├── components/          # 공통 컴포넌트 (레이아웃, 헤더, 푸터 등)
├── features/           # 기능별 모듈
│   ├── auth/          # 인증 (Context, Hooks, API)
│   ├── videocall/     # 영상 통화 (OpenVidu, FCM)
│   ├── fall/          # 낙상 감지 (WebSocket)
│   ├── schedule/      # 일정 관리
│   ├── minigame/      # 미니게임
│   └── weather/       # 날씨 정보
├── pages/             # 페이지 (DisplayPage, LoginPage)
├── hooks/             # 공통 Hooks (useIdle)
├── api/               # HTTP 클라이언트
└── test/              # 테스트 설정
```

각 feature는 다음 구조를 따릅니다:
- `context/` - React Context & Provider
- `hooks/` - Custom Hooks
- `components/` - UI 컴포넌트
- `services/` - API 호출
- `utils/` - 유틸리티 함수
- `constants/` - 상수

---

## 📡 Backend API

### 인증
```
POST /api/auth/login       # 로그인
POST /api/auth/logout      # 로그아웃
GET /api/auth/me          # 현재 사용자
```

### 영상 통화
```
POST /api/openvidu/sessions                           # 세션 생성
POST /api/openvidu/sessions/{id}/connections          # 토큰 발급
POST /api/openvidu/call/user                          # 개인 호출
POST /api/openvidu/call/users-by-pet                  # 모든 보호자 호출
POST /api/pets/fcm-token                              # FCM 토큰 등록
```

### 일정
```
GET /api/schedules                 # 일정 조회
POST /api/schedules                # 일정 추가
PUT /api/schedules/{id}            # 일정 수정
DELETE /api/schedules/{id}         # 일정 삭제
```

### 기타
```
GET /api/weather                   # 날씨 정보
WebSocket /ws/fall-detection       # 낙상 감지 스트림
```

---

## 🐛 트러블슈팅

| 문제 | 해결 방법 |
|------|---------|
| FCM 토큰 발급 실패 | 환경변수 확인, Firebase 설정 확인, Service Worker 존재 여부 확인 |
| 영상 통화 연결 안됨 | 백엔드 OpenVidu 서버 실행 확인, CORS 설정 확인 |
| 알림 권한 오류 | 브라우저 알림 권한 허용, HTTPS 사용 (프로덕션) |
| WebSocket 연결 실패 | 백엔드 WebSocket 엔드포인트 확인, 네트워크 확인 |

---

## 🔒 보안

- `.env` 파일은 Git에 커밋하지 않기 (.gitignore 확인)
- Firebase API Key는 도메인 제한 설정
- 프로덕션 환경에서는 HTTPS 필수
- Access Token은 로컬 스토리지가 아닌 HttpOnly 쿠키 권장

---

## 📚 참고 자료

- [OpenVidu 문서](https://docs.openvidu.io/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [React 공식 문서](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)
