# NOIL 빠른 시작 가이드

## 체크리스트

시작하기 전에 다음을 확인하세요:

- [ ] Ubuntu 22.04 설치됨
- [ ] ROS2 Humble 설치됨
- [ ] NVIDIA Jetson Orin Nano 준비됨
- [ ] Logitech Brio 연결됨
- [ ] UACDemo 스피커 연결됨
- [ ] 네트워크 연결 확인

---

## 1. 필수 시스템 설정 (Jetson Orin Nano)

> 이 단계는 **한 번만** 설정하면 됩니다. 수행하지 않으면 FPS 저하, STT/TTS 지연 등이 발생할 수 있습니다.
> `jetson_setup.sh` 스크립트로 자동화할 수 있습니다.

### 1-1. 최대 성능 모드

```bash
sudo nvpmodel -m 0
sudo jetson_clocks

# 확인
sudo nvpmodel -q
sudo jetson_clocks --show
```

### 1-2. 스왑 메모리 4GB

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 부팅 시 자동 활성화
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 확인
free -h
```

### 1-3. CPU Governor (performance)

```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

---

## 2. ROS2 및 패키지 설치

### 2-1. ROS2 Humble

```bash
sudo apt update
sudo apt install ros-humble-desktop
sudo apt install ros-humble-nav2-bringup ros-humble-navigation2 ros-humble-twist-mux
sudo apt install python3-colcon-common-extensions python3-rosdep

echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

### 2-2. Python 패키지

```bash
pip3 install --upgrade pip
pip3 install requests numpy sounddevice sherpa-onnx pycuda onnxruntime opencv-python
```

### 2-3. Sherpa-ONNX STT 모델 다운로드

```bash
cd ~
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-korean-2024-06-16.tar.bz2
tar -xf sherpa-onnx-streaming-zipformer-korean-2024-06-16.tar.bz2
```

---

## 3. 프로젝트 클론 및 빌드

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone <저장소 URL> .
```

### 의존성 설치 및 빌드

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install

source install/setup.bash
echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
```

또는 빌드 스크립트 사용:

```bash
./build_workspace.sh
```

---

## 4. 하드웨어 확인

### 카메라 (Logitech Brio)

```bash
v4l2-ctl --list-devices

# 권한 문제 시
sudo usermod -aG video $USER
```

### 마이크/스피커

```bash
python3 -c "import sounddevice as sd; print(sd.query_devices())"

# 테스트
arecord -d 3 test.wav
aplay test.wav
```

---

## 5. 설정 파일 수정

### 웨이포인트 (`core/no_ill_bringup/config/waypoints.yaml`)

```yaml
waypoints:
  - {x: 1.0, y: 2.0}
  - {x: 3.0, y: 4.0}
  - {x: 5.0, y: 1.0}
```

### 핫워드 (`stt/config/hotwords.txt`)

```
노일아:2.0
노일:1.5
로봇:1.0
```

### 서버 URL

`llm/llm/llm_node.py`:
```python
DEFAULT_AUTH_URL = "http://YOUR_SERVER:8080/api/auth/pets/login"
DEFAULT_TALK_URL = "http://YOUR_SERVER:8080/api/conversations/talk"
DEFAULT_PET_ID = "YOUR_PET_ID"
```

`upload_accident/upload_accident/upload_accident_node.py`:
```python
DEFAULT_UPLOAD_URL = "http://YOUR_SERVER:8080/api/events/report"
```

---

## 6. YOLO TensorRT 엔진 생성

```bash
cd ~/ros2_ws/src/perception/yolo_detector/models
trtexec --onnx=best.onnx --saveEngine=best.engine --fp16
```

---

## 7. 맵 생성 및 Nav2 설정

```bash
# 맵 생성 (환경에 따라 변경)
ros2 launch turtlebot3_cartographer cartographer.launch.py
ros2 run turtlebot3_teleop teleop_keyboard
ros2 run nav2_map_server map_saver_cli -f ~/maps/mymap
```

`core/no_ill_bringup/config/nav2_params.yaml`에서 맵 경로 설정:
```yaml
map_server:
  ros__parameters:
    yaml_filename: "/home/jetson/maps/mymap.yaml"
```

---

## 8. 실행 방법

### 방법 1: Launch 파일로 전체 실행 (권장)

```bash
ros2 launch no_ill_bringup noil_system.launch.py

# 백그라운드 실행
nohup ros2 launch no_ill_bringup noil_system.launch.py &
```

### 방법 2: 개별 노드 실행 (디버깅용)

```bash
ros2 run yolo_detector detector_node          # YOLO 감지
ros2 run fall_accident_judgement judgement_node # 낙상 판단
ros2 run stt stt_node                          # 음성 인식
ros2 run tts tts_node                          # 음성 합성
ros2 run llm llm_node                          # LLM 통신
ros2 run emergency_response emergency_response_node
ros2 run upload_accident upload_accident_node
ros2 run person_override person_override_node
ros2 run chat_stop_gate chat_stop_gate_node
```

### 방법 3: tmux로 한 화면에서 관리

```bash
sudo apt install tmux
tmux new -s noil

# 단축키
Ctrl+b, %       # 세로 분할
Ctrl+b, "       # 가로 분할
Ctrl+b, 방향키  # 창 이동
Ctrl+b, d       # 세션 detach
tmux attach -t noil  # 세션 복귀
```

### 방법 4: systemd 서비스 (자동 시작)

```bash
sudo nano /etc/systemd/system/noil.service
```

```ini
[Unit]
Description=NOIL Robot System
After=network.target

[Service]
Type=simple
User=jetson
WorkingDirectory=/home/jetson/ros2_ws
Environment="ROS_DOMAIN_ID=0"
ExecStart=/bin/bash -c "source /opt/ros/humble/setup.bash && source /home/jetson/ros2_ws/install/setup.bash && ros2 launch no_ill_bringup noil_system.launch.py"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable noil.service
sudo systemctl start noil.service
```

---

## 9. 정상 동작 체크

- [ ] YOLO 초기화 (3-5초 후 감지 시작)
- [ ] STT 초기화 비프음 2회
- [ ] TTS 초기화 비프음 2회
- [ ] Nav2 맵 로드 완료
- [ ] twist_mux 동작 정상 (대화 시 정지)

### 대화 시나리오 테스트

1. 로봇 순찰 중 **"노일아"** 호출
2. 로봇 정지 + "네, 말씀하세요" 출력
3. 질문 → STT → LLM → TTS 응답 확인
4. 7초 타임아웃 후 "대화를 종료합니다"

### 낙상 시나리오 테스트

1. 카메라 앞에서 **1.5초 이상 누워있기**
2. YOLO `lying` 30프레임 연속 → 낙상 감지
3. 낙상 지점 자동 주행 → "괜찮습니까?" 최대 5회
4. 무응답 시 캡처 + 서버 업로드

---

## 10. 모니터링 및 디버깅

```bash
ros2 topic list                        # 토픽 목록
ros2 topic echo /object_type           # 토픽 데이터 확인
ros2 topic hz /person_x                # 토픽 주파수
ros2 node list                         # 실행 중인 노드
ros2 node info /yolo_detector_node     # 노드 정보
sudo tegrastats                        # Jetson 리소스 모니터링
```

### 실행 중지

```bash
# Launch 중지: 실행 터미널에서 Ctrl+C
# 또는
pkill -f "ros2 launch"

# systemd 서비스 중지
sudo systemctl stop noil.service
```

---

## 11. 문제 해결

### YOLO 감지 안 됨
```bash
v4l2-ctl --list-devices
sudo usermod -aG video $USER
trtexec --onnx=best.onnx --saveEngine=best.engine --fp16
```

### 음성 인식 안 됨
```bash
python3 -c "import sounddevice as sd; print(sd.query_devices())"
pactl list sources | grep -i rate
```

### Nav2 주행 안 됨
```bash
ros2 topic echo /map
ros2 run tf2_tools view_frames
ros2 launch nav2_bringup navigation_launch.py log_level:=debug
```

### Package/Node not found
```bash
colcon build --packages-select <package_name>
source install/setup.bash
```
