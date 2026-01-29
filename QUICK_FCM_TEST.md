# FCM 토큰 빠른 테스트 가이드

## 🚀 5분 안에 FCM 토큰 테스트하기

### Step 1: 앱 실행 (30초)

```bash
flutter run
```

### Step 2: 터미널에서 로그 확인 (30초)

```bash
flutter logs
```

### Step 3: 로그인 수행 (2분)

1. 앱의 로그인 화면에서 유효한 ID/PW 입력
2. 로그인 버튼 클릭

### Step 4: 로그 확인 (1분)

다음 로그를 터미널에서 확인하세요:

```
✅ [FCM] 토큰 획득 성공: BwEZn...
🚀 [FCM] 서버로 토큰 전송 중...
✅ [FCM] 토큰 전송 성공
🔔 [FCM] 토큰 갱신 리스너 시작
✅ AuthNotifier: FCM 토큰 전송 및 리스너 등록 완료
```

---

## ✅ 성공 지표

| 표시 | 의미   |
| ---- | ------ |
| ✅   | 성공   |
| ❌   | 실패   |
| 🚀   | 시작   |
| 🔔   | 알림   |
| 💬   | 메시지 |

---

## ❌ 문제 해결

### "토큰 발급 실패" 에러

- Firebase 초기화 확인: `google-services.json` 파일 확인
- 재시도: 앱 완전 재설치

### "서버 전송 실패" 에러

- 백엔드 서버 실행 확인
- `.env` 파일의 `BASE_URL` 확인
- 네트워크 연결 확인

### "401 Unauthorized" 에러

- 로그인 다시 시도
- AccessToken 유효성 확인

---

## 🔧 고급 디버깅 (선택사항)

### 모든 저장된 토큰 확인

[lib/services/fcm_debug_service.dart](./lib/services/fcm_debug_service.dart)의 도우미 함수 사용:

```dart
// 진단 실행
FcmDebugService.diagnoseLoginStatus();

// 또는 개별 확인
FcmDebugService.getStoredAccessToken();      // AccessToken 확인
FcmDebugService.printCurrentFcmToken();      // FCM 토큰 확인
FcmDebugService.printAllStoredKeys();        // 모든 저장소 확인
```

### 로그 필터링

```bash
# FCM 관련 로그만 보기
flutter logs | grep "\[FCM\]"
```

---

## 📊 체크리스트

- [ ] 앱 실행
- [ ] 로그인
- [ ] "토큰 획득 성공" 로그 확인
- [ ] "토큰 전송 성공" 로그 확인
- [ ] 백엔드 서버 로그에서 200 응답 확인

---

**모든 체크 완료? 🎉 FCM 토큰이 성공적으로 백엔드로 전송되었습니다!**
