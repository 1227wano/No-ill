# 로봇 상태 관리 구현 계획 (Robot Status Management)

## 1. 개요
백엔드 서버에서 이동형 로봇(노일이)의 현재 상태(Status)를 중앙 관리하기 위한 기능을 구현합니다.
기존의 LLM 명령 기반 상태 변경(취침 모드 등)이 제외됨에 따라, **API를 통한 상태 조회 및 수동/자동 변경**에 집중합니다.

## 2. 상태(Status) 정의
로봇의 동작 모드를 정의하는 Enum입니다.

```java
public enum RobotStatus {
    NONE,   // 대기/기본 (초기화 전)
    PATROL, // 순찰 모드 (기본 동작)
    TRACK,  // 추적 모드 (사용자 팔로잉)
    SLEEP   // 취침 모드 (충전 복귀)
}
```

## 3. 구현 목표
### A. 상태 저장소 (In-Memory)
- **자료구조**: `ConcurrentHashMap<Long, RobotStatus>` (Thread-Safe)
- **Key**: 사용자/로봇 ID (`Long`)
- **Value**: 현재 상태 (`RobotStatus`)

### B. 초기 상태 전략 (바로 순찰 모드로 시작하려면?)
기본적으로 값은 `NONE`으로 초기화되지만, 로봇이 켜지자마자 활동을 시작해야 한다면 아래 두 가지 방법 중 하나를 선택합니다.

1.  **서버 측 기본값 변경 (추천)**:
    - `Map`에서 값을 꺼낼 때(`getOrDefault`), 값이 없으면 `PATROL`을 반환하도록 설정.
    - 장점: 로봇이 별도 요청 없이도 바로 순찰 모드로 인식.
2.  **클라이언트(로봇) 요청**:
    - 로봇 부팅 시 `POST /api/robot/status`를 호출하여 스스로를 `PATROL`로 설정.

### C. 기능 명세
1.  **상태 조회 (GET)**: 프론트엔드/로봇이 현재 상태 확인.
2.  **상태 변경 (POST)**: 특정 상황(버튼 클릭, 스케줄 등)에 따라 상태 업데이트.

## 4. 상세 구현 계획

### Step 1: Enum 생성
`com.noill.domain.robot.RobotStatus`

### Step 2: Service 구현
`com.noill.domain.robot.service.RobotStatusService`
- 상태 조회 메서드 (`getStatus`)
- 상태 변경 메서드 (`updateStatus`)

### Step 3: Controller 구현
`com.noill.domain.robot.controller.RobotStatusController`
- `GET /api/robot/status/{userId}`
- `POST /api/robot/status/{userId}` body: `{"status": "PATROL"}`
