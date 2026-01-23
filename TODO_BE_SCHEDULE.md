# 📋 Backend Task List: 일정 추가 기능 집중 구현

본 문서는 사용자의 발화에서 단일 일정을 추출하고 DB에 저장하는 기능을 최우선으로 구현하기 위한 가이드입니다.

---

## 🔧 0. LLM API 설정
| 항목 | 값 |
|---|---|
| **Endpoint** | `https://gms.ssafy.io/gmsapi/api.openai.com/v1/responses` |
| **Model** | `gpt-4.1` |
| **인증** | Bearer Token (`GMS_KEY` 환경변수) |
| **Content-Type** | `application/json` |

---

## 🏗️ 1. 데이터 모델링 (DTO & Entity)
- [x] **`ScheduleTextRequestDto`**: 노일이로부터 텍스트를 받는 객체 (`text`)
- [x] **`ScheduleAnalysisResponseDto`**: LLM의 분석 결과를 담는 객체 (`intent`, `title`, `datetime`, `message`)
- [x] **`Schedule` Entity**: JPA를 통해 DB에 저장될 도메인 모델 (`User`와 `@ManyToOne` 관계)
- [x] **`ScheduleRepository`**: 인터페이스 생성 (JPA 기본 기능 활용)

## 🧠 2. LLM 연동 및 파싱
- [x] **시스템 프롬프트 적용**: `@[NOILL_PROMPT_SYSTEM.md]` 파일의 내용을 시스템 프롬프트로 사용
- [x] **단일 목적 프롬프트 작성**: "일정 정보만 JSON으로 추출해줘" (Deprecated -> 통합 프롬프트 사용)
- [x] **현재 시간 주입**: 날짜 계산을 위해 `LocalDateTime.now()` 정보를 요청에 포함
- [x] **JSON 역직렬화 (Jackson)**: LLM의 String 응답을 `ScheduleResponseDto`로 변환

## 💾 3. 비즈니스 로직 (Service)
- [x] **의도 검증 로직**: `intent`가 `ADD_SCHEDULE`인 경우에만 DB 저장 로직 실행
- [x] **DB 저장 수행**: 파싱된 `title`과 `datetime`을 Entity에 담아 `save` 호출

## 🔄 4. 결과 반환
- [x] **로봇 피드백 전송**: 처리가 완료된 후 LLM이 생성한 `message`를 노일이에게 반환

---

## ⚠️ 5. 예외 처리 (Exception Handling)

### 5.1 예외 케이스 및 처리 방침
| 케이스 | 상황 | 처리 방법 |
|---|---|---|
| **빈 텍스트** | `text`가 null 또는 empty | LLM 호출 생략, 즉시 오류 메시지 반환 |
| **LLM 응답 파싱 실패** | JSON 형식 오류, 필수 필드 누락 | 기본 오류 메시지 반환 |
| **일정 정보 누락** | `title` 또는 `datetime`이 null | 재요청 안내 메시지 반환 |
| **intent 불일치** | `ADD_SCHEDULE`이 아닌 경우 | DB 저장 생략, 기본 응답 반환 |
| **LLM API 통신 오류** | 타임아웃, 네트워크 오류, 5xx 에러 | 재시도 1회 후 오류 메시지 반환 |

### 5.2 예외별 반환 메시지 (노일이 TTS용)
```java
public class ScheduleErrorMessages {
    // Service 내 상수 또는 메시지로 구현됨
}
```

### 5.3 구현 체크리스트
- [x] **`ScheduleErrorMessages`**: Service 내 하드코딩 또는 상수로 대체 구현됨
- [x] **빈 텍스트 검증**: Service 진입 시 검증 구현
- [x] **LLM 응답 파싱 try-catch**: `JsonProcessingException` 처리 구현
- [x] **필수 필드 null 체크**: `title`, `datetime` 검증 후 적절한 메시지 반환 구현
- [x] **API 호출 예외 처리**: `RestClientException` 등 처리 구현
- [ ] **재시도 로직**: API 오류 시 1회 재시도 구현 (선택사항 - 미구현)