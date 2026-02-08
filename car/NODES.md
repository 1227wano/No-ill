# 📘 NOIL 노드 상세 문서

## 목차

1. [Perception Layer](#1-perception-layer)
   - [yolo_detector_node](#yolo_detector_node)
   - [fall_judgement_node](#fall_judgement_node)
2. [Navigation Layer](#2-navigation-layer)
   - [waypoint_follower_node](#waypoint_follower_node)
   - [fall_point_navigator_node](#fall_point_navigator_node)
3. [Control Layer](#3-control-layer)
   - [person_override_node](#person_override_node)
   - [chat_stop_gate_node](#chat_stop_gate_node)
4. [Emergency Layer](#4-emergency-layer)
   - [emergency_response_node](#emergency_response_node)
   - [upload_accident_node](#upload_accident_node)
5. [AI Layer](#5-ai-layer)
   - [llm_node](#llm_node)
   - [stt_node](#stt_node)
   - [tts_node](#tts_node)

---

## 1. Perception Layer

### yolo_detector_node

**파일**: `src/perception/yolo_detector/yolo_detector/detector_node.py`

**기능**: TensorRT 최적화 YOLO 기반 실시간 객체 감지 및 추적

#### 토픽

**구독**:
- `/capture_command` (Bool) - 캡처 명령
- `/is_chatting` (Bool) - 대화 상태

**발행**:
- `/person_x` (Int32) - 감지된 사람들의 평균 X 좌표
- `/person_y` (Int32) - 감지된 사람들의 평균 Y 좌표
- `/object_type` (String) - "desk", "lying", "others"
- `/accident_cap` (Bool) - 캡처 완료 신호
- `/test_beep` (String) - 카메라 초기화 비프

#### 파라미터

```python
MODEL_WIDTH = 224
MODEL_HEIGHT = 224
CONFIDENCE_THRESHOLD = 0.70
NMS_THRESHOLD = 0.4
MAX_DISAPPEARED = 15
```

#### 동작 원리

1. **카메라 입력**: 224×160 → 224×224 레터박스 패딩
2. **TensorRT 추론**: FP16 최적화 (20 FPS)
3. **NMS**: 중복 박스 제거
4. **객체 추적**: ID 기반 트래킹 (최대 15프레임 소실)
5. **클래스 안정화**: 15프레임 히스토리로 다수결

#### 클래스 정의

- **desk**: 책상 (추적 대상 제외)
- **lying**: 누워있음 (낙상 의심)
- **others**: 서있거나 앉음 (정상)

#### 특수 동작

- `is_chatting=True` 시: "others" 10회 발행 → person_override 추적 중단
- `capture_command=True` 시: 현재 프레임 저장 (~/Downloads/N0111.jpg)

---

### fall_judgement_node

**파일**: `src/perception/fall_accident_judgement/fall_accident_judgement/judgement_node.py`

**기능**: 연속 "lying" 감지를 통한 낙상 판단

#### 토픽

**구독**:
- `/object_type` (String) - YOLO 감지 결과

**발행**:
- `/check_accident` (Bool) - 낙상 사고 여부

#### 파라미터

```python
LYING_THRESHOLD = 30        # 낙상 판단 임계값 (프레임)
COOLDOWN_SECONDS = 10.0     # 재감지 쿨다운 (초)
LOG_INTERVAL = 10           # 로그 출력 간격
```

#### 상태 머신

```
[IDLE] → "lying" 수신 → count++
        ↓
        count < 30 → 계속 대기
        count >= 30 → [TRIGGERED]
                        ↓
                  check_accident=True
                        ↓
                  10초 쿨다운
                        ↓
                  [IDLE 복귀]
```

#### 오탐 방지

- 중간에 "others" 감지 시 카운트 리셋
- 30프레임 연속 (1.5초 @ 20Hz)만 낙상 인정

---

## 2. Navigation Layer

### waypoint_follower_node

**파일**: `src/navigation/waypoint_follower/src/waypoint_follower_node.cpp`

**기능**: YAML 파일 기반 웨이포인트 순환 순회

#### 토픽

**발행**:
- `/cmd_vel` (Twist) - Nav2로 목표 전송

#### 파라미터

```cpp
waypoint_file: "waypoints.yaml"
arrival_threshold: 0.5  // 도착 판정 거리 (m)
rate: 1.0               // 체크 주기 (Hz)
```

#### YAML 형식

```yaml
waypoints:
  - {x: 1.0, y: 2.0}
  - {x: 3.0, y: 4.0}
  - {x: 5.0, y: 1.0}
```

#### 동작 원리

1. YAML 파일에서 웨이포인트 로드
2. 첫 번째 목표 Nav2로 전송
3. 도착 확인 (유클리드 거리 < 0.5m)
4. 다음 웨이포인트로 이동
5. 마지막 → 첫 번째 (순환)

---

### fall_point_navigator_node

**파일**: `src/navigation/fall_point_navigator/src/fall_point_navigator_node.cpp`

**기능**: 낙상 지점 자동 주행 및 복귀

#### 토픽

**구독**:
- `/check_accident` (Bool) - 낙상 감지

**발행**:
- `/cmd_vel` (Twist) - Nav2 목표
- `/fall_arrived` (Bool) - 도착 신호

#### 상태 머신

```
[IDLE] → check_accident=True → [NAVIGATING]
                                    ↓
                              낙상 지점 도착
                                    ↓
                            fall_arrived=True
                                    ↓
                              [WAIT_RESPONSE]
                                    ↓
                         check_accident=False
                                    ↓
                            [RETURNING_HOME]
                                    ↓
                              원래 위치 복귀
                                    ↓
                                [IDLE]
```

#### 동작 원리

1. 낙상 감지 시 현재 위치 저장
2. 웨이포인트 순회 중단
3. 낙상 지점 주행
4. 도착 후 fall_arrived=True 발행
5. 응급 대응 완료 대기
6. 원래 위치로 복귀
7. 웨이포인트 순회 재개

---

## 3. Control Layer

### person_override_node

**파일**: `src/control/person_override/src/person_override_node.cpp`

**기능**: 사람 발견 시 자동 추적 주행

#### 토픽

**구독**:
- `/person_x` (Int32) - 사람 X 좌표
- `/person_y` (Int32) - 사람 Y 좌표
- `/object_type` (String) - 객체 타입

**발행**:
- `/cmd_vel_person` (Twist) - 추적 명령 (우선순위 50)

#### 파라미터

```cpp
kp: 0.005              // PID P 게인
target_x: 112          // 목표 X 좌표 (중앙)
linear_speed: 0.2      // 전진 속도
max_angular: 0.8       // 최대 각속도
stop_threshold: 10     // 추적 중단 카운트
```

#### 제어 로직

```cpp
// PID 제어
error = target_x - person_x
angular_z = kp * error

// 속도 제한
angular_z = clamp(angular_z, -max_angular, max_angular)

// Twist 발행
twist.linear.x = linear_speed
twist.angular.z = angular_z
```

#### 추적 중단 조건

- "lying" 감지 (낙상 의심)
- "others" 10회 연속 (대화 모드)

---

### chat_stop_gate_node

**파일**: `src/control/chat_stop_gate/src/chat_stop_gate_node.cpp`

**기능**: 대화 중 로봇 강제 정지

#### 토픽

**구독**:
- `/is_chatting` (Bool) - 대화 상태

**발행**:
- `/cmd_vel_is_chatting` (Twist) - 정지 명령 (우선순위 300)

#### 파라미터

```cpp
publish_rate: 10.0  // 발행 주기 (Hz)
```

#### 동작 원리

1. `is_chatting=True` 수신
2. 10Hz로 정지 명령 지속 발행
3. twist_mux 우선순위 300 (최고)
4. 다른 모든 주행 명령 무시

#### twist_mux 우선순위

```
300: chat_stop_gate    (대화 중 정지)
 50: person_override   (사람 추적)
 10: Nav2              (자율 주행)
```

---

## 4. Emergency Layer

### emergency_response_node

**파일**: `src/emergency_response/emergency_response/emergency_response_node.py`

**기능**: 낙상 시 자동 응급 대응 시퀀스

#### 토픽

**구독**:
- `/fall_arrived` (Bool) - 낙상 지점 도착
- `/emergency_stt_result` (String) - 환자 응답
- `/emergency_tts_done` (Bool) - TTS 완료

**발행**:
- `/tts_trigger` (String) - 질문 TTS
- `/force_listen` (Bool) - STT 강제 청취
- `/capture_command` (Bool) - 캡처 명령
- `/is_chatting` (Bool) - 주행 제어
- `/check_accident` (Bool) - 사고 상태 리셋
- `/fall_arrived` (Bool) - 낙상 상태 리셋

#### 상태 머신

```
IDLE → ARRIVED → ASKING → WAITING
                    ↑         ↓
                    └─(재시도)─┘
                              ↓
                        [응답 있음]
                              ↓
                          ENDING
                              ↓
                        COOLDOWN → IDLE

                    [5회 무응답]
                              ↓
                        REPORTING
                              ↓
                        ENDING
                              ↓
                        COOLDOWN → IDLE
```

#### 파라미터

```python
MAX_ATTEMPTS = 5            # 최대 질문 횟수
RESPONSE_TIMEOUT = 5.0      # 응답 대기 시간
COOLDOWN_DURATION = 3600.0  # 쿨다운 1시간
```

#### 긍정 응답 키워드

```python
POSITIVE_KEYWORDS = ["응", "어", "괜찮", "됐", "네", "예"]
```

---

### upload_accident_node

**파일**: `src/upload_accident/upload_accident/upload_accident_node.py`

**기능**: 사고 이미지 서버 업로드

#### 토픽

**구독**:
- `/accident_cap` (Bool) - 캡처 완료 신호

#### 파라미터

```python
image_name: "N0111.jpg"
save_directory: "~/Downloads"
upload_url: "http://i14a301.p.ssafy.io:8080/api/events/report"
max_retries: 3
request_timeout: 10.0
```

#### API 명세

```
POST /api/events/report
Content-Type: multipart/form-data

Request:
  file: (binary) JPEG 이미지

Response (200):
  {
    "success": true,
    "message": "Report submitted",
    "eventId": 12345
  }
```

#### 재시도 로직

1. 첫 시도 실패 → 1초 대기
2. 두 번째 시도 실패 → 1초 대기
3. 세 번째 시도 실패 → 최종 실패

---

## 5. AI Layer

### llm_node

**파일**: `src/llm/llm/llm_node.py`

**기능**: 백엔드 LLM 서버 통신

#### 토픽

**구독**:
- `/stt_result` (String) - 음성 인식 결과

**발행**:
- `/llm_response` (String) - LLM 응답

#### 파라미터

```python
auth_url: "http://i14a301.p.ssafy.io:8080/api/auth/pets/login"
talk_url: "http://i14a301.p.ssafy.io:8080/api/conversations/talk"
pet_id: "N0111"
auth_timeout: 10.0
talk_timeout: 15.0
```

#### API 명세

**인증**:
```
POST /api/auth/pets/login

Request:
  {"petId": "N0111"}

Response:
  {"accessToken": "eyJ..."}
```

**대화**:
```
POST /api/conversations/talk
Authorization: Bearer <token>

Request:
  {"petId": "N0111", "content": "안녕"}

Response:
  {"reply": "안녕하세요!"}
```

#### JWT 토큰 관리

- 초기화 시 자동 발급
- 401 응답 시 재발급
- 최대 3회 재시도

---

### stt_node

**파일**: `src/stt/stt/stt_node.py`

**기능**: Sherpa-ONNX 기반 한국어 음성 인식

#### 토픽

**구독**:
- `/tts_done` (Bool) - TTS 완료
- `/force_listen` (Bool) - 강제 청취
- `/stt_mute` (Bool) - 마이크 뮤트

**발행**:
- `/is_chatting` (Bool) - 대화 상태
- `/stt_result` (String) - 일반 인식
- `/emergency_stt_result` (String) - 응급 인식

#### 파라미터

```python
SAMPLE_RATE = 16000
CONVERSATION_TIMEOUT = 7.0
MODEL_DIR = "/home/jetson/sherpa-onnx/..."
```

#### 동작 모드

**1. 핫워드 대기 모드**:
- 지속적인 음성 인식
- 핫워드 감지 → 대화 모드 전환
- 10번 중 1번만 로그 (성능)

**2. 대화 모드**:
- TTS 완료 후 청취 시작
- 사용자 발화 대기
- 7초 타임아웃

**3. 응급 모드**:
- `force_listen=True` 시 활성화
- 핫워드 없이 즉시 청취
- `emergency_stt_result` 발행

#### 핫워드 파일 (hotwords.txt)

```
노일아:2.0
노일:1.5
로봇:1.0
```

---

### tts_node

**파일**: `src/tts/tts/tts_node.py`

**기능**: Sherpa-ONNX 기반 한국어 음성 합성

#### 토픽

**구독**:
- `/llm_response` (String) - 일반 대화
- `/tts_trigger` (String) - 응급 메시지
- `/is_chatting` (Bool) - 대화 상태
- `/fall_arrived` (Bool) - 응급 모드
- `/test_beep` (String) - 테스트 비프

**발행**:
- `/tts_done` (Bool) - 일반 TTS 완료
- `/emergency_tts_done` (Bool) - 응급 TTS 완료
- `/stt_mute` (Bool) - STT 뮤트

#### 파라미터

```python
TARGET_SAMPLE_RATE = 48000
PLAYBACK_SPEED = 0.9
POST_PLAY_DELAY = 0.35
```

#### 모델 설정

```python
models/
├── tts_model.onnx  # VITS 모델
└── tokens.txt      # 한국어 토큰
```

#### 비프음

**TTS 초기화 (2회)**:
- 주파수: 440Hz (A4)
- 길이: 0.2초

**카메라 초기화 (3회)**:
- 주파수: 880Hz (A5)
- 길이: 0.15초

#### 재생 흐름

1. `stt_mute=True` 발행
2. 음성 합성 (Sherpa-ONNX)
3. 0.9배속 리샘플링
4. 스피커 출력
5. 0.35초 여유 시간
6. `stt_mute=False` 발행
7. 완료 신호 발행

---

## 📊 토픽 관계도

```
┌──────────────┐
│     YOLO     │──┬→ /person_x ────→ person_override
└──────────────┘  ├→ /person_y ────→ person_override
                  ├→ /object_type ─→ fall_judgement
                  └→ /accident_cap → upload_accident

┌──────────────┐
│fall_judgement│──→ /check_accident → fall_point_navigator
└──────────────┘                    → emergency_response

┌──────────────┐
│fall_navigator│──→ /fall_arrived ─→ emergency_response
└──────────────┘                    → tts

┌──────────────┐
│emergency_resp│──┬→ /capture_command → yolo_detector
└──────────────┘  ├→ /force_listen ──→ stt
                  ├→ /tts_trigger ───→ tts
                  └→ /is_chatting ──→ chat_stop_gate
                                     → yolo_detector
                                     → tts

┌──────────────┐
│     STT      │──┬→ /is_chatting ──→ [여러 노드]
└──────────────┘  ├→ /stt_result ───→ llm
                  └→ /emergency_stt → emergency_response

┌──────────────┐
│     LLM      │──→ /llm_response ─→ tts
└──────────────┘

┌──────────────┐
│     TTS      │──┬→ /tts_done ────→ stt
└──────────────┘  ├→ /emergency_tts → emergency_response
                  └→ /stt_mute ────→ stt
```

---

## 🔍 디버깅 팁

### 토픽 모니터링

```bash
# 특정 토픽 확인
ros2 topic echo /object_type
ros2 topic echo /is_chatting

# 토픽 주파수 확인
ros2 topic hz /person_x

# 토픽 목록
ros2 topic list
```

### 노드 상태 확인

```bash
# 실행 중인 노드
ros2 node list

# 노드 정보
ros2 node info /yolo_detector_node

# 파라미터 확인
ros2 param list /stt_node
```

### 로그 레벨 변경

```bash
# 특정 노드만 DEBUG
ros2 run yolo_detector detector_node --ros-args --log-level DEBUG

# launch 파일에서
ros2 launch no_ill_bringup noil_system.launch.py log_level:=DEBUG
```

---

**문서 작성일**: 2026년 2월 8일
**버전**: 1.0
