# Jetson Orin Nano 시뮬레이션 환경 (WSL2)

WSL2에서 Jetson Orin Nano와 유사한 개발/테스트 환경을 구축하기 위한 Docker 컨테이너 설정입니다.

## 환경 스펙 비교

| 항목 | Jetson Orin Nano | WSL2 컨테이너 | 비고 |
|------|------------------|---------------|------|
| CPU 코어 | 6코어 (ARM64) | 6코어 (x86_64) | 코어 수 동일 |
| 메모리 | 8GB | 8GB | 동일 |
| GPU 메모리 | 4-6GB (공유) | 6GB 제한 권장 | 코드 레벨 제한 |
| OS | Ubuntu 22.04 (JetPack 6.0) | Ubuntu 22.04 | 동일 |
| CUDA | 12.2 | 12.0 | 유사 |

## 제한 사항

- **GPU 성능**: 호스트 GPU(RTX 등)가 Jetson보다 훨씬 빠름
- **아키텍처**: ARM64가 아닌 x86_64 환경
- **실제 성능 테스트는 Jetson 보드에서 수행 필요**

## 테스트 가능 항목

- 메모리 초과(OOM) 오류 확인
- GPU VRAM 부족 상황 테스트
- 코드/라이브러리 호환성 검증
- CPU 병목 확인
- 다중 서비스 동시 실행 부하 테스트

---

## 빠른 시작

### 1. 저장소 클론 및 환경 구축

```bash
# WSL2 Ubuntu에서 실행

# 저장소 클론
git clone https://lab.ssafy.com/s14-webmobile1-sub1/S14P11A301.git
cd S14P11A301

# 줄바꿈 변환 (Windows에서 편집한 경우)
sed -i 's/\r$//' jetson-orin-nano-wsl2-setup.sh

# 실행 권한 부여
chmod +x jetson-orin-nano-wsl2-setup.sh

# Docker 컨테이너 생성
./jetson-orin-nano-wsl2-setup.sh
```

스크립트는 실행 위치를 자동 감지하여 컨테이너에 마운트합니다.

### 2. 의존성 설치

```bash
# 컨테이너 접속
docker exec -it jetson-sim bash

# 의존성 설치 (최초 1회)
cd /workspace
sed -i 's/\r$//' tests/install_dependencies.sh
chmod +x tests/install_dependencies.sh
./tests/install_dependencies.sh
```

### 3. 통합 부하 테스트 실행

```bash
cd /workspace/tests
python3 integrated_load_test.py -d 60
```

---

## 설치되는 패키지

| 카테고리 | 패키지 | 용도 |
|----------|--------|------|
| 딥러닝 | PyTorch + CUDA | GPU 연산 |
| 객체 인식 | YOLOv8 (ultralytics) | 사람/객체 감지 |
| STT | Whisper | 음성 인식 (한국어) |
| TTS | gTTS | 음성 합성 (한국어) |
| 영상 처리 | OpenCV | 영상 스트리밍 |
| 모니터링 | psutil, pynvml | 리소스 측정 |

---

## 사용 방법

### 컨테이너 접속

```bash
docker exec -it jetson-sim bash
```

### 컨테이너 상태 확인

```bash
# 실행 상태
docker ps

# 리소스 사용량
docker stats jetson-sim --no-stream

# GPU 확인
docker exec -it jetson-sim nvidia-smi
```

### 컨테이너 관리

```bash
# 중지
docker stop jetson-sim

# 시작
docker start jetson-sim

# 삭제 후 재생성
docker rm -f jetson-sim
./jetson-orin-nano-wsl2-setup.sh
```

---

## 통합 부하 테스트

Jetson Orin Nano에서 실행할 기능들을 동시에 실행하여 부하를 측정합니다.

### 테스트 항목

| 서비스 | 설명 | 기본 설정 |
|--------|------|-----------|
| 2D 라이다 | 주행용 스캔 시뮬레이션 | 10Hz |
| 화상통화 | 영상 스트리밍 | 720p @ 30fps |
| 객체 인식 | YOLOv8n 추론 | 10fps |
| STT | Whisper 음성 인식 | 3초마다 |
| TTS | gTTS 음성 합성 (한국어) | 2초마다 |

### 테스트 실행

```bash
# 기본 실행 (60초)
python3 tests/integrated_load_test.py

# 시간 지정 (120초)
python3 tests/integrated_load_test.py -d 120
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
 Jetson Orin Nano 대비 평가
============================================================
[OK] GPU 메모리 사용량 적정 (4409MB / 6144MB)
[OK] RAM 사용량 적정 (1421MB / 8192MB)
============================================================
```

### 결과 해석

| 항목 | 정상 범위 | 경고 |
|------|-----------|------|
| GPU 메모리 | < 6GB | Jetson에서 OOM 발생 가능 |
| RAM | < 7GB | 메모리 부족 가능 |
| CPU | < 90% | 병목 발생 가능 |

---

## 설정 변경

`tests/config.py` 파일에서 모델 및 설정을 변경할 수 있습니다.

### 커스텀 모델 사용

```python
# 객체 인식 - 커스텀 PyTorch 모델
OBJECT_DETECTION = {
    "type": "custom_torch",
    "custom_model_path": "/workspace/models/my_detection.pt",
    "input_size": (640, 640),
    "inference_interval": 0.1,
}

# STT - Whisper 모델 크기 변경
STT = {
    "type": "whisper",
    "whisper_model": "small",  # tiny, base, small, medium, large
    "language": "ko",
    "process_interval": 3.0,
}

# TTS - gTTS 한국어
TTS_CONFIG = {
    "type": "gtts",
    "gtts_lang": "ko",
    "synthesis_interval": 2.0,
}
```

### 지원 모델 형식

| 서비스 | 지원 형식 |
|--------|-----------|
| 객체 인식 | YOLO (.pt), PyTorch (.pt), TFLite (.tflite) |
| STT | Whisper (tiny/base/small/medium/large) |
| TTS | gTTS (한국어), Coqui TTS |

---

## GPU 메모리 제한 (코드 레벨)

컨테이너 내부에서 PyTorch/TensorFlow 사용 시 GPU 메모리를 제한합니다.

### PyTorch

```python
import torch
torch.cuda.set_per_process_memory_fraction(0.375)  # 16GB * 0.375 = 6GB
```

### TensorFlow

```python
import tensorflow as tf
gpus = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_virtual_device_configuration(
    gpus[0],
    [tf.config.experimental.VirtualDeviceConfiguration(memory_limit=6144)]
)
```

---

## ROS2 설치 (선택사항)

실제 라이다 연동이 필요한 경우 ROS2를 설치합니다.

```bash
# 컨테이너 내부에서
apt update && apt install -y curl gnupg lsb-release

# ROS2 저장소 추가
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | tee /etc/apt/sources.list.d/ros2.list

# ROS2 Humble 설치
apt update && apt install -y ros-humble-desktop
source /opt/ros/humble/setup.bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

# 확인
ros2 doctor
```

---

## 디렉토리 구조

```
/workspace/
├── jetson-orin-nano-wsl2-setup.sh  # Docker 환경 구축 스크립트
├── README.md                        # 이 문서
└── tests/
    ├── install_dependencies.sh      # 의존성 설치 스크립트
    ├── config.py                    # 테스트 설정 파일
    └── integrated_load_test.py      # 통합 부하 테스트
```

## 디렉토리 마운트

| 호스트 경로 | 컨테이너 경로 |
|-------------|---------------|
| (스크립트 실행 위치) | `/workspace` |

## 포트 매핑

| 호스트 | 컨테이너 | 용도 |
|--------|----------|------|
| 8080 | 8080 | 웹 서비스 |

---

## 문제 해결

### Docker 권한 오류

```bash
# Docker 그룹에 사용자 추가
sudo usermod -aG docker $USER
newgrp docker
```

### GPU 인식 안 됨

```bash
# NVIDIA 드라이버 확인 (WSL2 외부에서)
nvidia-smi

# Container Toolkit 재설치
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo service docker restart
```

### 줄바꿈 오류 (bad interpreter)

```bash
sed -i 's/\r$//' 파일명.sh
```
