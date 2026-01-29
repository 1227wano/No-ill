# 📋 Backend Task List: 노일이 대화 시스템 구현 (Conversation System)

본 문서는 `NOILL_CONVERSATION_SYSTEM.md` 명세에 따라 노일이의 **장기 기억(Long-term Memory)** 및 **대화 세션 관리** 시스템을 구현하기 위한 상세 체크리스트입니다.

---

## 🏗️ 1. 데이터 모델링 (Entity & Repository) [**최우선 작업**]
세션과 메시지를 저장할 DB 테이블 구조를 잡습니다. (JPA 활용)

> ⚠️ **엔티티 구현/수정 시 반드시 `erd.png`를 참고하여 테이블 관계를 확인하세요.**

### 1.1 Entity 구현
- [x] **`Schedule` Entity 수정 (`User` -> `Pet` 연결 변경)**
  - 현재 `User`와 직접 연결된 FK를 `Pet`(`petNo`) 연결로 수정 (ERD 준수).
- [x] **`Talks` Entity (세션)**
  - `talkNo` (PK), `petNo` (FK - `Pets` 테이블 참조)
  - `talkName` (Not Null, 초기값 필요)
  - `status` (Enum: `Y`=Active, `N`=Closed)
- [x] **`Messages` Entity (대화)**
  - `msgNo` (PK)
  - `talks` (ManyToOne, FK: `talk_no`): **어떤 세션의 대화인지 식별**
  - `msgType` (Enum/Char: `Q`=User, `A`=Bot)
  - `msgContent` (Text)
  - `createdAt` (대화 시점, 타임아웃 판별 기준)


### 1.2 Repository 구현
- [x] **Session Repository**
  - **마지막 활성 세션 조회**: 특정 반려동물의 가장 최근 활성화된 세션을 조회하는 기능.
  - **과거 기억 검색**: 키워드를 포함하는 과거 세션 제목을 검색하는 기능.
- [x] **Message Repository**
  - **오래된 메시지 정리**: 특정 세션의 메시지가 일정 개수를 초과할 경우, 가장 오래된 질의응답 쌍을 삭제하는 기능.

---

## � 2. 범용 응답 객체 및 DTO 설계
LLM과 각 서비스 간의 "계약서"를 먼저 정의합니다.

- [x] **범용 응답 객체 (`LlmAnalysisResult`) 생성**: 
  - 필드: `intent` (Enum: SCHEDULE, TALK), `payload` (Map/JsonNode), `rawMessage` (String).
- [x] **Legacy DTO 분리**: 기존 `ScheduleAnalysisResponseDto`는 `Schedule` 도메인으로 격리하고, `LlmService`는 이를 반환하지 않도록 수정.

---

## �🛠️ 3. LLM 공통 아키텍처 개선 (Dispatcher & Intent Classification)
기존 `LlmService`가 일정(Schedule) 도메인에 종속된 문제를 해결하고, 대화의 의도를 먼저 파악하여 적절한 서비스로 분기하는 구조를 확립합니다.

### 3.1 LLM 서비스 범용화 (Refactoring)
- [x] **`LlmService` 위치 이동 및 패키지 신설**: `domain.schedule.service` -> **`domain.conversation.service`** (핵심 도메인으로 격상)
  - `Schedule`, `User`, `Pet`과 동등한 레벨의 `Conversation` 도메인 정의.
- [x] **`Intent` 판별 프롬프트 수정**: 
  - **엄격한 분류**: 구체적 날짜/시간 + 할 일이 모두 있을 때만 `add_schedule`.
  - **기본값**: 단순 감정 표현, 인사 등은 무조건 `daily_talk`.
- [x] **프롬프트 명세 동기화**: `NOILL_PROMPT_SYSTEM.md` 파일 업데이트 및 코드 내 시스템 프롬프트와 일치시키기.
- [x] **Multi-Prompt 구조 지원**: `LlmService` 내에서 목적에 따라 다른 시스템 프롬프트를 사용할 수 있도록 메소드 분리.
  - `analyzeUserCommand`: 사용자 발화 의도 분석 (일정 vs 대화).
  - `generateSessionTitle`: 대화 내용을 바탕으로 50자 이내의 세션 제목 생성 (요약).
- [x] **장애 대응 전략 (Fallback)**: LLM API 타임아웃/에러 시 즉시 "잠시 문제가 생겼어요" 등의 기본 안전 응답 반환 로직 구현.

### 3.2 대화 분기 처리 (Dispatcher Service)
- [x] **진입점 구현 (Facade Pattern)**: 클라이언트(로봇)의 요청을 받는 단일 진입점(`RobotInteractionService`) 생성.
- [x] **분기 로직 (Routing Logic)**:
  - **Case 1 (Schedule)**: `cmdType='add_schedule'` 식별 -> `ScheduleService` 호출 (DB 저장).
  - **Case 2 (Chat)**: `cmdType='daily_talk'` 식별 -> `ConversationService` 호출 (대화 기억 및 세션 저장). - *(`ConversationService` 연결은 TODO 상태)*
- [x] **통합 엔드포인트 설계 (Unified Endpoint)**:
  - 로봇/클라이언트는 `POST /api/conversation/talk` (가칭) 하나의 경로로만 모든 발화를 전송.
  - "일정 등록"을 위해 별도의 `/api/schedules`를 클라이언트가 직접 호출하지 않음 (Dispatcher가 내부적으로 처리).
- [x] **로봇 응답 표준화**: DB 저장 로직과 무관하게 로봇은 일관된 포맷(TTS 메시지 등)을 수신.

---

## 🧠 4. 비즈니스 로직 (Service Layer)
핵심 대화 처리 프로세스를 구현합니다.

### 4.1 세션 매니저 (`ConversationService`)
- [x] **세션 운영 로직 (Strict 3-Hour Rule)**
  - **세션 판별**: 사용자가 말을 걸면 해당 유저의 마지막 메시지 시각(`CREATED_AT`)을 확인합니다.
  - **분기 처리**:
    - **3시간 미만 경과**: 기존 `TALK_NO`를 유지하여 대화를 이어갑니다.
    - **3시간 이상 경과**: 무조건 새로운 `Talks` 레코드를 생성하고 새로운 `TALK_NO`를 발급합니다. (자정 구분 없이 오직 시간 간격 기준)
- [x] **트랜잭션 분리 전략 (Performance Optimization)**
  > LLM API 호출(Latency) 동안 DB 커넥션을 점유하지 않도록 트랜잭션을 단계별로 분리합니다.
  - **Phase 1 (`@Transactional`):** 세션 타임아웃 체크 (3시간 규칙 적용) -> (새 세션 생성/기존 종료) -> 사용자 메시지(`Q`) 저장.
  - **Phase 2 (No Transaction):** LLM 호출하여 응답 생성
  - **Phase 3 (`@Transactional`):** LLM 응답(`A`) 저장 -> **Rolling Window 트리거:** 저장 후 **전체 메시지가 50개를 초과하면 가장 오래된 Q&A 한 쌍(2개)을 삭제**.
- [x] **구현 상세**
  - **메인 처리 메소드**: 전체 흐름을 제어하고 각 Phase를 조율.
  - **사용자 메시지 저장 메소드**: Phase 1 담당 (3시간 타임아웃 체크 포함).
  - **봇 메시지 저장 메소드**: Phase 3 담당.

### 4.2 LLM 연동 확장 (`LlmService`)
- [x] **동적 프롬프트 생성 (Simultaneous Injection Strategy)**
  > 효율성을 위해 **현재 대화(History)** 와 **관련 기억(Memory)** 을 한 번의 프롬프트에 모두 담아 LLM에게 판단을 맡깁니다.
  1. **History 조회:** 현재 세션의 최근 메시지 N개 (필수).
  2. **Memory 검색:** 사용자 발화 키워드로 과거 세션 제목 검색
  3. **Context 우선순위 로직:** 
     - 정보를 찾을 때 **현재 대화(History)** 내에서 연관 내용을 먼저 판별.
     - 현재 대화에 관련 내용이 없을 경우에만 **과거 기억(Memory)** 을 참조하도록 프롬프트/로직 구성.
  4. **Prompt 구성:**
     - `System`: 페르소나 정의
     - `[Memory]`: (검색된 과거 대화 제목들...)
     - `[History]`: (Q/A/Q/A...)
     - `User`: (현재 발화)
- [x] ~~**제목 생성 비동기 처리**~~  
  - -> **Cancelled**: 테스트 복잡성 및 트랜잭션 이슈로 인해 **'스케줄러에 의한 일괄 요약'**으로 전략 변경.

---

## ⏰ 5. 배치 스케줄러 (Batch Job)
대화가 끝난 세션을 정리하고 기억을 강화합니다.

- [x] **세션 종료 및 요약 스케줄러**
  - **주기:** 1시간마다 실행
  - **대상:** `STATUS='Y'` 이면서 마지막 대화로부터 3시간이 지난 세션 조회.
  - **동작:** 
    1. 대상 세션의 전체 대화 내용 조회.
    2. LLM에게 "세션 제목(요약)" 요청 (50자 이내).
    3. `Talks` 엔티티의 `talkName` 업데이트 및 `STATUS='N'` 변경.
    4. 해당 로직을 처리하는 배치 서비스 호출 (순차 처리).

  - **구현 단계 (Implementation Steps):**
    - [x] **Step 5-1. Repository**: `TalkRepository`에 `JOIN` 및 `GROUP BY`를 사용하여 마지막 메시지가 3시간 지난 세션 조회 쿼리(JPQL) 구현.
    - [x] **Step 5-2. Entity Logic**: `Talk` 엔티티에 `close(String summaryTitle)` 메서드 추가.
    - [x] **Step 5-3. Batch Service**: `ConversationBatchService` 구현.
      - `closeExpiredSessions()`: 대상 조회 및 루프 (No Transaction).
      - `processSingleSession()`: 개별 LLM 요약 및 DB 업데이트 (Service 위임으로 `REQUIRES_NEW` 적용).
    - [x] **Step 5-4. Config**: `@EnableScheduling` 추가.
    
---

## ✅ 6. 통합 테스트 및 검증
- [ ] **DB 연동 테스트:** 세션 생성, 메시지 적재 확인.
- [ ] **삭제 로직 검증:** 메시지를 52개 넣었을 때 2개가 지워지고 50개가 남는지 확인.
- [ ] **기억 소환 테스트:** 과거에 "허리가 아파"라고 저장된 세션이 있을 때, 현재 대화에서 관련 키워드 언급 시 프롬프트에 포함되는지 로그 확인.