# NOILL_CONVERSATION_SYSTEM (대화 시스템 명세)

본 문서는 노일이(No-ill)의 대화 세션 관리, DB 스키마 정의, 데이터 최적화 정책을 정의합니다.
**주의:** 본 시스템은 현재 버전에서 **RAG(Vector Embedding)** 를 구현하지 않으며, **DB 기반의 제목 검색(Lightweight Retrieval)** 방식을 채택합니다.

## 1. 데이터베이스 스키마 설계 (Entity Definition)

사용자가 DB를 직접 수정하므로, 본 항목은 개발 시 참고할 **테이블 명세서** 역할을 합니다.

### 1.1 테이블: Talks (대화 목록)
- **용도:** 사용자의 대화 세션을 관리하는 테이블. 3시간 단위로 하나의 레코드가 생성됩니다.
- **Columns:**
  - `TALK_NO` (PK, INT): 세션 고유 식별자.
  - `PET_NO` (FK, INT): 보호 대상 노인 식별자.
  - `TALK_NAME` (VARCHAR, NOT NULL): 대화의 주제/요약. (초기값: 날짜시간, 이후 LLM 요약으로 업데이트)
  - `STATUS` (VARCHAR/ENUM): 세션 상태 (`Y`: 진행 중, `N`: 종료됨).

### 1.2 테이블: Messages (대화 내용)
- **용도:** 세션 내 오고 간 개별 메시지를 저장하는 테이블.
- **Columns:**
  - `MSE_NO` (PK, INT): 메시지 고유 식별자 (Auto Increment).
  - `TALK_NO` (FK, INT): 소속 세션 ID.
  - `MSG_TYPE` (CHAR(1), NOT NULL): 발화자 구분 (`Q`: 노인/User, `A`: 로봇/Assistant).
  - `MSG_CONTENT` (TEXT/VARCHAR): 실제 대화 내용.
  - `CREATED_AT` (DATETIME, NOT NULL): **메시지 생성(저장) 시간**. (세션 타임아웃 판별의 기준)

---

## 2. 세션 운영 라이프사이클 (Session Lifecycle)

### 2.1 세션 시작 및 초기화
- **조건:** (현재 시간 - 마지막 메시지의 `CREATED_AT`) >= **3시간**
- **동작:**
  - 새 `Talks` 레코드 생성.
  - `TALK_NAME` 초기값: `"YYYY-MM-DD HH:mm 대화"` (임시 제목, NOT NULL 제약 준수)
  - `STATUS`: `'Y'`

### 2.2 제목 요약 및 업데이트 (LLM 연동)
- **API Key & 연동:** `GMS_API_KEY` 환경변수를 사용하여 `LlmService.java` 내의 로직을 활용합니다. (RestTemplate 사용)
- **업데이트 전략 (Batch Only):**
  - **정책:** 실시간 제목 생성은 지연 시간 및 트랜잭션 복잡도 문제로 인해 사용하지 않습니다.
  - **Trigger:** 배치 작업(`ScheduledTasks`, 1시간 주기)에 의해 **세션 종료(`STATUS -> N`)** 시점에 실행됩니다.
  - **Action:** 전체 대화 내용을 LLM에 보내 **내용을 요약한 제목(20자 이내)** 을 생성하여 `Talks.TALK_NAME`을 업데이트합니다.

---

## 3. 메모리 및 검색 전략 (Retrieval Policy)
... (기존 3, 4번 섹션 유지)

---

## 5. 대화 기반 일정 등록 (Intent Recognition)
사용자의 발화에서 일정을 파악하여 자동으로 `schedules` 테이블에 등록합니다.

- **프로세스:**
  1. `ConversationService`가 사용자 발화를 `LlmService`에 전달.
  2. LLM이 JSON 포맷으로 `cmd: add_schedule` 응답.
  3. `ConversationService`가 이를 감지하여 `ScheduleService.addScheduleFromLlm()` 호출.
  4. `ScheduleService`가 `schedules` 테이블에 저장 후 결과 메시지 반환.
- **연관 관계(주의):**
  - 현재 `Pet` -> `User` 직접 참조가 없어 임시 로직 사용 중.
  - 추후 `Cares` 테이블 연동 시 정확한 보호자(`User`) 매핑 필요.

---

## 3. 메모리 및 검색 전략 (Retrieval Policy)

🚫 **제약 사항 (Strict Constraint):**
> 현재 단계에서는 **Vector DB, Embedding, Cosine Similarity** 등의 RAG 기술을 **절대 구현하지 않습니다.**
> 오직 RDBMS(MySQL)의 기능을 활용한 검색만 수행합니다.

### 3.1 구현 방식: 키워드 매칭 (JPA)
1. **키워드 추출:** 사용자 발화에서 의미 있는 명사(예: 병원, 아들, 김치)를 추출합니다.
2. **DB 검색:**
   - Spring Data JPA의 메소드를 활용하거나 Native Query를 사용합니다.
   - 예: `findTop3ByStatusAndTalkNameContainingOrderByCreatedAtDesc(Status.N, keyword)`
3. **프롬프트 주입:**
   - 검색된 과거 세션이 있다면, 시스템 프롬프트의 `<Memory>` 섹션에 해당 세션의 `TALK_NAME`을 주입하여 문맥을 형성합니다.

---

## 4. 데이터 최적화: Rolling Window (Q&A Pair Deletion)

시스템 성능 유지 및 토큰 절약을 위해 세션 당 메시지 수를 엄격히 제한합니다.

- **Threshold:** 세션 당 최대 **50개** 메시지 유지.
- **삭제 정책 (Pair Deletion):**
  - 51번째 메시지가 들어오면, 가장 오래된 메시지 **2개(Q 1개 + A 1개)** 를 한꺼번에 삭제합니다.
  - **기술적 구현 (JPA):** 
    - `LIMIT`를 사용한 삭제는 표준 JPQL에서 지원하지 않을 수 있으므로 **Native Query**(`@Query(value = "...", nativeQuery = true)`)를 사용하는 것이 효율적입니다.
  - **SQL 예시:**
    ```sql
    DELETE FROM messages 
    WHERE mse_no IN (
        SELECT mse_no FROM (
            SELECT mse_no FROM messages 
            WHERE talk_no = ? 
            ORDER BY mse_no ASC 
            LIMIT 2
        ) as temp
    );
    ```

