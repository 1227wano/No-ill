# Jetson Orin Nano 빠른 시작 가이드

## 1. 환경 세팅

```bash
chmod +x setup.sh
./setup.sh
sudo reboot
```

## 2. API 키 설정

```bash
cp .env.example .env
vi .env  # LLM_API_KEY 설정
```

## 3. 실행

```bash
source .env
ros2 launch no_ill_bringup no_ill_full.launch.py
```

## 4. 개별 노드 테스트

```bash
source .env
ros2 run yolo_detector yolo_detector_node
ros2 run stt stt_node
ros2 run tts tts_node
ros2 run llm llm_node
```

## 5. 부팅 시 자동 실행 (선택)

```bash
sudo cp noill.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable noill
sudo systemctl start noill

# 로그 확인
journalctl -u noill -f
```

## 파라미터 오버라이드

```bash
# 예: 마이크 장치명 변경
ros2 run stt stt_node --ros-args -p mic_device_name:="USB Audio"

# 예: 낙상 감지 임계치 변경
ros2 run fall_accident_judgement judgement_node --ros-args -p threshold:=20
```

## 전체 토픽 목록

### YOLO 감지 (yolo_detector)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/person_x` | Int32 | Pub | 감지된 사람 X 좌표 (화면 중심 기준) |
| `/person_y` | Int32 | Pub | 감지된 사람 Y 좌표 |
| `/object_type` | String | Pub | "Lying" 또는 "others" |
| `/accident_cap` | Bool | Pub | 낙상 캡처 완료 알림 |
| `/check_accident` | Bool | Sub | 낙상 판단 결과 수신 |

### 낙상 판단 (fall_accident_judgement)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/object_type` | String | Sub | YOLO 감지 결과 수신 |
| `/check_accident` | Bool | Pub | 낙상 사고 판단 결과 (True=낙상) |

### 음성 인식 (stt)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/is_chatting` | Bool | Pub | 대화 모드 상태 (핫워드 감지 시 True) |
| `/stt_result` | String | Pub | 음성 인식 결과 텍스트 |
| `/tts_done` | Bool | Sub/Pub | TTS 완료 신호 (수신 및 내부 트리거) |

### LLM (llm)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/stt_result` | String | Sub | 음성 인식 결과 수신 |
| `/llm_response` | String | Pub | LLM 응답 텍스트 |

### 음성 합성 (tts)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/llm_response` | String | Sub | LLM 응답 수신 |
| `/is_chatting` | Bool | Sub | 대화 종료 시 "종료합니다" 출력 |
| `/tts_done` | Bool | Pub | TTS 재생 완료 알림 |

### 사고 업로드 (upload_accident)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/accident_cap` | Bool | Sub | 캡처 완료 시 서버로 이미지 업로드 |

### 사람 추적 (person_override)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/person_x` | Int32 | Sub | 사람 X 좌표 수신 |
| `/object_type` | String | Sub | 객체 타입 수신 |
| `/check_accident` | Bool | Sub | 낙상 판단 결과 수신 |
| `/cmd_vel_out` | Twist | Pub | 추적 기반 모터 명령 |
| `/fall_arrived` | Bool | Pub | 낙상 지점 도착 알림 |
| `/is_chatting` | Bool | Pub | 대화 모드 시작 알림 |

### 대화 정지 게이트 (chat_stop_gate)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/is_chatting` | Bool | Sub | 대화 중이면 모터 정지 |
| `/cmd_vel_out` | Twist | Pub | 게이트 통과 후 모터 명령 |

### 안전 오버라이드 (safety_override)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/scan` | LaserScan | Sub | 라이다 스캔 데이터 |
| `/cmd_vel_out` | Twist | Pub | 장애물 회피 적용 모터 명령 |

### 모터 드라이버 (pca_drive)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/cmd_vel_out` | Twist | Sub | 최종 모터 명령 수신 (PCA9685로 전달) |

### 라이다 (ydlidar)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/scan` | LaserScan | Pub | 라이다 스캔 데이터 |
| `/point_cloud` | PointCloud | Pub | 포인트 클라우드 데이터 |

### 레이저 오도메트리 (rf2o_laser_odometry)

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/scan` | LaserScan | Sub | 라이다 스캔 데이터 |
| `/odom` | Odometry | Pub | 추정된 오도메트리 |

### 테스트/디버그

| 토픽 | 타입 | 방향 | 설명 |
|------|------|------|------|
| `/cmd_vel` | Twist | Pub | 키보드 수동 제어 (keyboard_latch) |
| `/steer_cmd` | Float32 | Pub | 조향 명령 테스트 (tracking_drive_test) |
