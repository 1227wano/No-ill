# 노일(No-ill) - Jetson Orin Nano 로봇 시스템

독거노인 돌봄 로봇 "노일"의 Jetson Orin Nano 구동 코드 및 WSL2 시뮬레이션 환경입니다.

## 프로젝트 구조

```
├── jetson/                            # 실제 Jetson Orin Nano 구동 코드
│   └── ros2_ws/                       # ROS2 워크스페이스
│       ├── src/                       # 소스 패키지 (18개)
│       ├── config/                    # Nav2, twist_mux 설정
│       └── maps/                      # SLAM 지도 파일
│
├── tests/                             # WSL2 가상 테스트 환경
│   ├── config.py                      # 테스트 설정
│   ├── integrated_load_test.py        # 통합 부하 테스트
│   └── install_dependencies.sh        # 의존성 설치
│
├── jetson-orin-nano-wsl2-setup.sh     # Docker 환경 구축 스크립트
└── README.md
```

---

## Jetson Orin Nano 구동 코드

### ROS2 패키지 구성

| 카테고리 | 패키지 | 기능 |
|---------|--------|------|
| **센서** | `ydlidar_ros2_driver` | YDLidar X4-Pro 라이다 드라이버 |
| | `rf2o_laser_odometry` | 레이저 기반 오도메트리 |
| **비전/AI** | `yolo_detector` | YOLOv11 TensorRT 사람 감지 (Lying/others) |
| | `fall_accident_judgement` | 낙상 사고 판단 (30프레임 연속 Lying 감지) |
| | `upload_accident` | 사고 이미지 서버 업로드 |
| **음성** | `stt` | Sherpa-ONNX 음성인식 (핫워드 감지) |
| | `tts` | Sherpa-ONNX 음성합성 |
| | `llm` | GPT API 연동 대화 처리 |
| **제어** | `pca_drive` | PCA9685 PWM 모터 제어 |
| | `safety_override_pkg` | 장애물 회피 (긴급정지/감속) |
| | `person_override_pkg` | 사람 추적 주행 (PID 제어) |
| | `chat_stop_gate` | 대화 중 정지 게이트 |
| **런치** | `no_ill_bringup` | 전체 시스템 통합 런치 |
| | `robot_bringup` | Nav2 네비게이션 런치 |
| | `my_robot_bringup` | SLAM 매핑/텔레옵 런치 |

### 데이터 흐름

```
[카메라] → yolo_detector → fall_judgement → upload_accident → 서버
              │
              └→ person_override → twist_mux → pca_drive → 모터

[마이크] → stt_node → llm_node → tts_node → 스피커
              │
              └→ chat_stop_gate → 주행 정지
```

### 실행 방법

```bash
# Jetson Orin Nano에서
cd ~/ros2_ws
colcon build
source install/setup.bash

# 전체 시스템 실행
ros2 launch no_ill_bringup no_ill_full.launch.py
```

---

## WSL2 시뮬레이션 환경

Jetson Orin Nano 배포 전 부하 테스트를 위한 Docker 환경입니다.

### 환경 스펙 비교

| 항목 | Jetson Orin Nano | WSL2 컨테이너 |
|------|------------------|---------------|
| CPU | 6코어 (ARM64) | 6코어 (x86_64) |
| 메모리 | 8GB | 8GB |
| GPU 메모리 | 4-6GB (공유) | 6GB 제한 |
| CUDA | 12.2 | 12.0 |

### 테스트 가능 항목

- 메모리 초과(OOM) 오류 확인
- GPU VRAM 부족 상황 테스트
- 다중 서비스 동시 실행 부하 측정

### 빠른 시작

```bash
# WSL2 Ubuntu에서 실행

# 줄바꿈 변환 및 실행 권한
sed -i 's/\r$//' jetson-orin-nano-wsl2-setup.sh
chmod +x jetson-orin-nano-wsl2-setup.sh

# Docker 컨테이너 생성
./jetson-orin-nano-wsl2-setup.sh

# 컨테이너 접속
docker exec -it jetson-sim bash

# 의존성 설치 (최초 1회)
cd /workspace
sed -i 's/\r$//' tests/install_dependencies.sh
chmod +x tests/install_dependencies.sh
./tests/install_dependencies.sh

# 통합 부하 테스트 실행 (60초)
cd /workspace/tests
python3 integrated_load_test.py -d 60
```

### 테스트 결과 예시

```
============================================================
 테스트 결과
============================================================
CPU 사용률:     평균 2.7% / 최대 16.6%
RAM 사용량:     평균 1363.9MB / 최대 1421.4MB
GPU 메모리:     평균 4333.6MB / 최대 4409.2MB
GPU 사용률:     평균 23.3% / 최대 62.0%

처리량:
  - 라이다 스캔:    593회 (9.9/초)
  - 영상 프레임:    1529회 (25.5/초)
  - 객체 인식:      506회 (8.4/초)
  - STT 변환:       17회
  - TTS 합성:       25회
============================================================
```

### 설정 변경

`tests/config.py`에서 모델 및 테스트 설정을 변경할 수 있습니다.

```python
# GPU 메모리 제한 (Jetson 6GB 시뮬레이션)
GPU_MEMORY_FRACTION = 0.375  # 16GB * 0.375 = 6GB

# 객체 인식 설정
OBJECT_DETECTION = {
    "type": "yolo",
    "yolo_model": "yolov8n.pt",
    "inference_interval": 0.1,  # 10fps
}

# STT 설정
STT = {
    "type": "whisper",
    "whisper_model": "base",
    "language": "ko",
}
```

---

## 컨테이너 관리

```bash
# 상태 확인
docker ps
docker stats jetson-sim --no-stream

# GPU 확인
docker exec -it jetson-sim nvidia-smi

# 중지/시작
docker stop jetson-sim
docker start jetson-sim

# 삭제 후 재생성
docker rm -f jetson-sim
./jetson-orin-nano-wsl2-setup.sh
```

---

## 문제 해결

### Docker 권한 오류

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### GPU 인식 안 됨

```bash
# NVIDIA Container Toolkit 재설치
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo service docker restart
```

### 줄바꿈 오류 (bad interpreter)

```bash
sed -i 's/\r$//' 파일명.sh
```