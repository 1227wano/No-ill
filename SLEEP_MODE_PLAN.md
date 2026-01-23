# 수면 모드 구현 계획 (사용자 요청 요약)

## 1. 핵심 요청 사항 요약
팀원 요청에 따라 백엔드 서버에서 **로봇의 상태(Status)**를 관리할 수 있는 기능을 구현합니다.
우선적으로 **수면(취침) 모드** 저장을 목표로 합니다.

1. **입력 흐름**
   - 사용자 발화 (STT) → LLM 분석 → `"cmdType": "sleep_start"` 반환.

2. **상태 관리 방식 (중요)**
   - **백엔드 서버 내 변수**로 상태를 관리합니다. (DB 저장 아님, 메모리 변수 활용)
   - 로봇의 상태 종류:
     - **취침 (SLEEP)** - *구현 대상*
     - 추적 (TRACK)
     - 순찰 (PATROL)

3. **구현 목표**
   - `sleep_start` 명령이 들어오면 서버 변수에 **'취침'** 상태를 저장합니다.
   - 추후 이 변수 값을 로봇에게 전달하여 로봇이 현재 상태를 알 수 있게 합니다.

---

## 2. 상세 구현 계획

### A. 상태(Status) 정의
```java
public enum RobotStatus {
    SLEEP,  // 취침
    TRACK,  // 추적
    PATROL, // 순찰
    NONE    // 대기/기본
}
```

### B. 상태 저장소 (State Variable)
서버 메모리 상에 사용자별 상태를 저장할 변수를 선언합니다.
```java
// 예시: 사용자 ID를 Key로 사용하는 Map
private Map<Long, RobotStatus> robotStates = new ConcurrentHashMap<>();
```

### C. 로직 처리
1. **LlmService**: STT 입력을 분석해 `sleep_start` 커맨드 감지.
2. **ScheduleService**: 
   - `sleep_start` 커맨드 수신 시, 위 **상태 저장소**의 값을 `SLEEP`으로 업데이트.
   - 사용자에게는 "안녕히 주무세요" 등의 응답 반환.
