# FCM 토큰 백엔드 전송 테스트 가이드

## 📋 목차

1. [테스트 환경 설정](#테스트-환경-설정)
2. [테스트 방법](#테스트-방법)
3. [콘솔 로그 확인](#콘솔-로그-확인)
4. [디버깅 팁](#디버깅-팁)
5. [API 테스트](#api-테스트-방법)

---

## 테스트 환경 설정

### 1️⃣ 필수 조건

- ✅ Firebase 프로젝트 설정 완료
- ✅ Google Services JSON 파일 구성
- ✅ 백엔드 서버 실행 중 (`/api/notifications/token` 엔드포인트)
- ✅ 테스트 기기 or 에뮬레이터

### 2️⃣ 환경변수 확인 (.env)

```env
BASE_URL=http://localhost:8080  # 테스트용
# BASE_URL=https://i14a301.p.ssafy.io  # 프로덕션
```

---

## 테스트 방법

### 🔍 테스트 1: 콘솔 로그로 토큰 확인

#### 1단계: 앱 실행 및 로그 모니터링

```bash
# 터미널에서 로그 스트림 시작
flutter logs
```

#### 2단계: 로그인 수행

1. 앱 실행
2. 로그인 화면에서 유효한 ID/PW 입력
3. 로그인 버튼 클릭

#### 3단계: 다음 로그를 확인합니다

```
✅ [FCM] 토큰 획득 성공: BwE...
🚀 [FCM] 서버로 토큰 전송 중...
✅ [FCM] 토큰 전송 성공
🔔 [FCM] 토큰 갱신 리스너 시작
✅ AuthNotifier: FCM 토큰 전송 및 리스너 등록 완료
```

✅ **성공 표시**: 위 메시지가 모두 출력되면 토큰이 성공적으로 전송된 것입니다.

---

### 🔍 테스트 2: 백엔드 서버 로그 확인

#### 서버에서 토큰이 수신되었는지 확인

```bash
# Spring Boot 백엔드 로그에서
# POST /api/notifications/token 요청이 성공 (200)으로 처리됐는지 확인

# 예상 로그:
# 2026-01-29 14:35:22 [HTTP-nio-8080-exec-1] POST /api/notifications/token
# Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
# Body: {"token": "BwEZn8K..."}
# Response: 200 OK
```

#### 데이터베이스 확인

```sql
-- 사용자의 FCM 토큰이 저장됐는지 확인
SELECT user_id, fcm_token FROM user_notification_tokens
WHERE user_id = '로그인한_사용자ID'
ORDER BY updated_at DESC;
```

---

### 🔍 테스트 3: Postman으로 API 직접 테스트

#### 1단계: Postman 요청 설정

```
Method: POST
URL: http://localhost:8080/api/notifications/token
Headers:
  - Authorization: Bearer {your_access_token}
  - Content-Type: application/json
Body (Raw JSON):
{
  "token": "BwEZn8K..."
}
```

#### 2단계: 응답 확인

✅ **성공 (200)**:

```json
{
  "success": true,
  "message": "FCM 토큰이 저장되었습니다"
}
```

❌ **실패**:

```json
{
  "success": false,
  "message": "토큰 저장 실패: 유효하지 않은 토큰"
}
```

---

## 콘솔 로그 확인

### 🎯 로그인 후 예상되는 순서

| 순서 | 로그 메시지                       | 의미                        |
| ---- | --------------------------------- | --------------------------- |
| 1    | `✅ [FCM] 토큰 획득 성공: BwE...` | Firebase에서 토큰 획득 성공 |
| 2    | `🚀 [FCM] 서버로 토큰 전송 중...` | 백엔드로 전송 시작          |
| 3    | `✅ [FCM] 토큰 전송 성공`         | 토큰이 백엔드에 저장됨      |
| 4    | `🔔 [FCM] 토큰 갱신 리스너 시작`  | 토큰 갱신 감지 활성화       |
| 5    | `💬 [FCM] 포그라운드 메시지 수신` | 앱 실행 중 메시지 수신      |

### ⚠️ 에러 로그 및 해결방법

| 에러                      | 원인                      | 해결방법                       |
| ------------------------- | ------------------------- | ------------------------------ |
| `❌ [FCM] 토큰 발급 실패` | Firebase 초기화 실패      | firebase_options.dart 확인     |
| `❌ [FCM] 서버 전송 실패` | 네트워크 오류             | BASE_URL 확인, 서버 실행 확인  |
| `401 Unauthorized`        | accessToken 유효하지 않음 | 로그인 다시 시도               |
| `타임아웃`                | 네트워크 느림             | FCM Service의 타임아웃 값 증가 |

---

## 디버깅 팁

### 1️⃣ 상세 로그 보기

```bash
# FCM 관련 로그만 필터링
flutter logs | grep "\[FCM\]"
```

### 2️⃣ 토큰 갱신 테스트

Firebase 콘솔 또는 Admin SDK에서 토큰 갱신 강제 실행:

```bash
# 앱을 다시 설치하거나, Firebase 콘솔에서
# 디바이스 토큰 갱신 트리거
```

### 3️⃣ 토큰 값 직접 확인

디버그 로그에서 토큰 전체 값을 보려면 auth_provider.dart 수정:

```dart
// FCM Service의 getFcmToken() 호출 후
final fcmToken = await fcmService.getFcmToken();
print('DEBUG: Full FCM Token = $fcmToken'); // 토큰 전체 출력
```

### 4️⃣ Shared Preferences로 저장된 토큰 확인 (Android)

```bash
adb shell
su
cat /data/data/com.example.noill_app/shared_prefs/flutter.xml | grep fcm
```

---

## API 테스트 방법

### cURL로 테스트

```bash
# accessToken을 넣고 실행
curl -X POST http://localhost:8080/api/notifications/token \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token":"BwEZn8K..."}'
```

### JavaScript (Fetch API)

```javascript
const token = "BwEZn8K...";
const accessToken = "eyJhbGciOiJIUzI1NiIs...";

fetch("http://localhost:8080/api/notifications/token", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ token }),
})
  .then((res) => res.json())
  .then((data) => console.log("Success:", data))
  .catch((err) => console.error("Error:", err));
```

---

## 🎯 전체 플로우 테스트 체크리스트

- [ ] 1. 앱 실행 후 `flutter logs` 확인
- [ ] 2. 로그인 수행
- [ ] 3. `✅ [FCM] 토큰 획득 성공` 로그 확인
- [ ] 4. `✅ [FCM] 토큰 전송 성공` 로그 확인
- [ ] 5. 백엔드 서버 로그에서 200 응답 확인
- [ ] 6. 데이터베이스에서 토큰 저장 확인
- [ ] 7. 앱을 강제 종료했다가 다시 실행 (토큰 갱신 테스트)
- [ ] 8. 토큰 갱신 로그 확인

---

## 📝 추가 참고사항

### 토큰 갱신이 되지 않는 경우

- Firebase 콘솔에서 프로젝트 설정 다시 확인
- google-services.json 업데이트
- 앱 완전 재설치

### 메시지를 수신하지 못하는 경우

1. 알림 권한 활성화 확인
2. 앱이 백그라운드에 있는지 확인
3. Firebase 콘솔의 "테스트 메시지" 기능으로 메시지 전송 테스트

### 프로덕션 테스트

```env
# .env 파일에서 URL 변경
BASE_URL=https://i14a301.p.ssafy.io
```

---

**문제 발생 시:** 콘솔 로그의 `[FCM]` 태그가 붙은 메시지를 우선적으로 확인하세요! 🔍
