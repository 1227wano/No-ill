# No-Ill 백엔드 서버

노인 케어 IoT 플랫폼의 백엔드 서버입니다. Spring Boot를 기반으로 한 REST API 및 실시간 통신을 제공합니다.

## 📋 목차

- [기술 스택](#기술-스택)
- [개발 환경 설정](#개발-환경-설정)
- [설치 및 실행](#설치-및-실행)
- [프로젝트 구조](#프로젝트-구조)
- [API 문서](#api-문서)
- [주요 기능](#주요-기능)

---

## 🛠 기술 스택

**Backend**: Spring Boot 3.4.1, Java 21
**데이터베이스**: MySQL, Redis
**실시간 통신**: WebSocket, Stomp
**인증**: Spring Security, JWT
**API 클라이언트**: OpenVidu Java Client 2.30.0, Firebase Admin SDK 9.2.0
**통신**: Solapi (SMS), Firebase Cloud Messaging
**개발 도구**: Gradle, Lombok, Swagger

---

## 🚀 개발 환경 설정

### 1. 필수 요구사항
- Java 21 이상
- Gradle 7.0 이상
- MySQL 8.0 이상
- Redis 6.0 이상

### 2. 환경 변수 설정

`.env` 파일 생성:

```bash
# Database
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/noill
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=password

# Redis
SPRING_REDIS_HOST=localhost
SPRING_REDIS_PORT=6379

# JWT
JWT_SECRET_KEY=your_secret_key_min_256_bits
JWT_EXPIRATION=3600000

# OpenVidu
OPENVIDU_URL=http://localhost:4443
OPENVIDU_SECRET=MY_SECRET

# Firebase
FIREBASE_CREDENTIALS_PATH=path/to/firebase-key.json

# Solapi (SMS)
SOLAPI_API_KEY=your_solapi_api_key
SOLAPI_API_SECRET=your_solapi_api_secret

# LLM API
LLM_API_KEY=your_llm_api_key
LLM_API_URL=your_llm_api_url
```

### 3. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. 서비스 계정 키 JSON 파일 다운로드
3. `.env`의 `FIREBASE_CREDENTIALS_PATH`에 파일 경로 설정

### 4. MySQL 데이터베이스 생성

```bash
mysql -u root -p
CREATE DATABASE noill CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## 🚀 설치 및 실행

### 1. 의존성 설치
```bash
./gradlew clean build
```

### 2. 개발 서버 실행
```bash
./gradlew bootRun
```

서버가 `http://localhost:8080`에서 실행됩니다.

### 3. 프로덕션 빌드
```bash
./gradlew clean build -Dorg.gradle.jvmargs="-Xmx2g"
```

생성된 JAR 파일은 `build/libs/`에 위치합니다.

### 4. JAR 실행
```bash
java -jar build/libs/noill-0.0.1-SNAPSHOT.jar
```

### 5. Swagger API 문서
```
http://localhost:8080/swagger-ui.html
```

---

## 📁 프로젝트 구조

```
server/
├── src/main/java/com/noill/
│   ├── domain/                    # 비즈니스 로직 (DDD 패턴)
│   │   ├── user/                 # 사용자 인증 및 관리
│   │   ├── pet/                  # 펫(로봇, 디스플레이) 관리
│   │   ├── care/                 # 돌봄 데이터
│   │   ├── conversation/         # 대화 및 LLM 연동
│   │   ├── event/                # 이벤트 (낙상 감지 등)
│   │   ├── notification/         # 알림 (FCM, SMS)
│   │   ├── schedule/             # 일정 관리
│   │   ├── weather/              # 날씨 정보
│   │   └── openvidu/             # 영상 통화
│   │
│   └── global/                    # 글로벌 설정
│       ├── config/               # Spring 설정
│       ├── exception/            # 예외 처리
│       ├── redis/                # Redis 설정 및 유틸리티
│       ├── security/             # JWT 인증
│       └── websocket/            # WebSocket 설정
│
├── src/main/resources/
│   ├── application.yml           # Spring 설정
│   └── db/migration/             # Flyway DB 마이그레이션
│
└── build.gradle                  # Gradle 설정
```

### 각 Domain의 구조

```
domain/xxx/
├── controller/      # API 엔드포인트
├── service/         # 비즈니스 로직
├── repository/      # 데이터 접근
├── entity/          # JPA 엔티티
└── dto/             # 요청/응답 DTO
```

---

## 📡 API 문서

### 인증
```
POST /api/auth/login              # 로그인
POST /api/auth/logout             # 로그아웃
POST /api/auth/refresh            # 토큰 갱신
GET /api/auth/me                  # 현재 사용자
```

### 펫
```
GET /api/pets                      # 펫 목록
GET /api/pets/{id}                # 펫 상세
POST /api/pets                     # 펫 추가
PUT /api/pets/{id}                # 펫 수정
```

### 돌봄
```
GET /api/care/{petId}             # 돌봄 기록 조회
POST /api/care/{petId}            # 돌봄 기록 추가
```

### 대화 (Conversation)
```
POST /api/conversation/talk       # 대화 요청
GET /api/conversation/history     # 대화 이력
POST /api/conversation/analyze    # LLM 분석
```

### 이벤트 (낙상 감지 등)
```
GET /api/events                    # 이벤트 조회
POST /api/events                   # 이벤트 생성
GET /api/events/{id}              # 이벤트 상세
```

### 알림
```
GET /api/notifications             # 알림 조회
PUT /api/notifications/{id}/read   # 알림 읽음 표시
DELETE /api/notifications/{id}     # 알림 삭제
```

### 일정
```
GET /api/schedules                 # 일정 조회
POST /api/schedules                # 일정 추가
PUT /api/schedules/{id}            # 일정 수정
DELETE /api/schedules/{id}         # 일정 삭제
```

### 날씨
```
GET /api/weather                   # 날씨 정보
GET /api/weather/forecast          # 날씨 예보
```

### 영상 통화 (OpenVidu)
```
POST /api/openvidu/sessions        # 세션 생성
POST /api/openvidu/sessions/{id}/connections   # 토큰 발급
GET /api/openvidu/sessions         # 세션 목록
DELETE /api/openvidu/sessions/{id} # 세션 종료
```

### WebSocket
```
WS /ws/notifications              # 실시간 알림
WS /ws/conversation               # 실시간 대화
WS /ws/event                       # 실시간 이벤트 감지
```

---

## 🔌 주요 기능

### 인증 & 권한
- JWT 기반 토큰 인증
- Redis에 토큰 저장 및 관리
- Spring Security로 엔드포인트 보호

### 실시간 통신
- WebSocket을 통한 실시간 알림
- STOMP 프로토콜 지원

### 영상 통화
- OpenVidu 통합 (1:1 실시간 통화)
- 세션 및 토큰 관리

### 푸시 알림
- Firebase Cloud Messaging (FCM)
- Solapi를 통한 SMS 전송

### LLM 통합
- 노인 특화 대화형 AI
- 의도 분석 및 감정 인식

### 데이터 관리
- 낙상 감지 이벤트 저장
- 돌봄 기록 및 건강 데이터
- 일정 및 메시지 관리

---

## 🔐 보안

- `.env` 파일은 Git에 커밋하지 않기
- JWT 토큰은 Redis에 저장 (세션 관리)
- 모든 비밀번호는 bcrypt로 암호화
- API 엔드포인트는 Spring Security로 보호
- HTTPS 필수 (프로덕션)

---

## 🐛 트러블슈팅

| 문제 | 해결 방법 |
|------|---------|
| 데이터베이스 연결 실패 | MySQL 실행 확인, 연결 설정 확인 |
| Redis 연결 실패 | Redis 서버 실행 확인, 포트 확인 |
| JWT 토큰 검증 실패 | JWT_SECRET_KEY 환경변수 확인 |
| OpenVidu 연결 실패 | OpenVidu 서버 실행 확인, URL 및 SECRET 확인 |
| Firebase 초기화 실패 | 서비스 계정 JSON 파일 경로 확인 |
| 포트 이미 사용 중 | 포트 변경: `server.port=8081` 설정 |

---

## 📚 참고 자료

- [Spring Boot 문서](https://spring.io/projects/spring-boot)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [Spring Security](https://spring.io/projects/spring-security)
- [OpenVidu 문서](https://docs.openvidu.io/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [WebSocket & STOMP](https://docs.spring.io/spring-framework/reference/web/websocket.html)

---

## 📞 API 문서 (Swagger)

서버 실행 후 아래 링크에서 API 명세를 확인할 수 있습니다:
```
http://localhost:8080/swagger-ui.html
```
