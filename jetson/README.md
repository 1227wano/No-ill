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

## 주요 토픽

| 토픽 | 타입 | 설명 |
|------|------|------|
| `/person_x` | Int32 | 감지된 사람 X 좌표 |
| `/object_type` | String | "Lying" 또는 "others" |
| `/check_accident` | Bool | 낙상 사고 감지 |
| `/stt_result` | String | 음성 인식 결과 |
| `/llm_response` | String | LLM 응답 |
| `/is_chatting` | Bool | 대화 모드 상태 |
| `/cmd_vel_out` | Twist | 최종 모터 명령 |
