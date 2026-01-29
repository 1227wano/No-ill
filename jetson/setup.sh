#!/bin/bash

# =============================================================================
# Jetson Orin Nano 환경 세팅 스크립트
# Ubuntu 22.04 + JetPack 6.0
# =============================================================================

set -e

echo "=========================================="
echo " Jetson Orin Nano 환경 세팅"
echo "=========================================="

# 스크립트 실행 위치
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROS2_WS="$SCRIPT_DIR/ros2_ws"

# =============================================================================
# 1. 시스템 패키지 업데이트
# =============================================================================
echo ""
echo "[1/8] 시스템 패키지 업데이트..."
sudo apt update && sudo apt upgrade -y

# =============================================================================
# 2. ROS2 Humble 설치
# =============================================================================
echo ""
echo "[2/8] ROS2 Humble 설치..."

# ROS2 저장소 추가
sudo apt install -y software-properties-common curl gnupg lsb-release
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt install -y ros-humble-desktop

# ROS2 환경 설정
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source /opt/ros/humble/setup.bash

# colcon 빌드 도구
sudo apt install -y python3-colcon-common-extensions python3-rosdep
sudo rosdep init 2>/dev/null || true
rosdep update

# =============================================================================
# 3. Nav2 및 SLAM 패키지 설치
# =============================================================================
echo ""
echo "[3/8] Nav2 및 SLAM 패키지 설치..."
sudo apt install -y \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-slam-toolbox \
    ros-humble-twist-mux \
    ros-humble-tf2-ros \
    ros-humble-tf2-tools

# =============================================================================
# 4. 기본 시스템 패키지 설치
# =============================================================================
echo ""
echo "[4/8] 기본 시스템 패키지 설치..."
sudo apt install -y \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    i2c-tools \
    libi2c-dev \
    portaudio19-dev \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1-mesa-glx

# =============================================================================
# 5. Python 패키지 설치
# =============================================================================
echo ""
echo "[5/8] Python 패키지 설치..."

pip3 install --upgrade pip

# 기본 패키지
pip3 install \
    numpy \
    opencv-python \
    requests \
    smbus2 \
    adafruit-circuitpython-pca9685 \
    adafruit-circuitpython-servokit

# 오디오 관련
pip3 install \
    sounddevice \
    soundfile

# =============================================================================
# 6. Sherpa-ONNX 설치 (STT/TTS)
# =============================================================================
echo ""
echo "[6/8] Sherpa-ONNX 설치 (STT/TTS)..."
pip3 install sherpa-onnx

# STT 모델 다운로드 (한국어 Zipformer)
STT_MODEL_DIR="$HOME/sherpa-onnx/sherpa-onnx-streaming-zipformer-korean-2024-06-16"
if [ ! -d "$STT_MODEL_DIR" ]; then
    echo "STT 모델 다운로드 중..."
    mkdir -p "$HOME/sherpa-onnx"
    cd "$HOME/sherpa-onnx"
    wget -q https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-korean-2024-06-16.tar.bz2
    tar xf sherpa-onnx-streaming-zipformer-korean-2024-06-16.tar.bz2
    rm sherpa-onnx-streaming-zipformer-korean-2024-06-16.tar.bz2
    echo "STT 모델 다운로드 완료: $STT_MODEL_DIR"
else
    echo "STT 모델이 이미 존재합니다: $STT_MODEL_DIR"
fi

# TTS 모델: tts 패키지의 models/ 폴더에 이미 포함되어 있음 (tts_model.onnx)
echo "TTS 모델: 패키지에 포함됨 (별도 다운로드 불필요)"

# =============================================================================
# 7. TensorRT (YOLO용) - JetPack에 포함되어 있음
# =============================================================================
echo ""
echo "[7/8] TensorRT 확인..."

# pycuda 설치
pip3 install pycuda

# TensorRT Python 바인딩 확인
python3 -c "import tensorrt; print(f'TensorRT 버전: {tensorrt.__version__}')" 2>/dev/null || {
    echo "WARNING: TensorRT Python 바인딩이 없습니다."
    echo "JetPack이 제대로 설치되어 있는지 확인하세요."
}

# =============================================================================
# 8. ROS2 워크스페이스 빌드
# =============================================================================
echo ""
echo "[8/8] ROS2 워크스페이스 빌드..."

cd "$ROS2_WS"

# 의존성 설치
rosdep install --from-paths src --ignore-src -r -y 2>/dev/null || true

# 빌드
source /opt/ros/humble/setup.bash
colcon build --symlink-install

# 환경 설정 추가
echo "source $ROS2_WS/install/setup.bash" >> ~/.bashrc

# =============================================================================
# I2C 권한 설정 (PCA9685용)
# =============================================================================
echo ""
echo "I2C 권한 설정..."
sudo usermod -aG i2c $USER

# =============================================================================
# 완료
# =============================================================================
# =============================================================================
# 환경변수 설정 파일 생성
# =============================================================================
echo ""
echo "환경변수 설정 파일 생성..."
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    echo ".env 파일이 생성되었습니다. API 키를 설정하세요:"
    echo "  vi $SCRIPT_DIR/.env"
else
    echo ".env 파일이 이미 존재합니다."
fi

echo ""
echo "=========================================="
echo " 설치 완료!"
echo "=========================================="
echo ""
echo "1. 환경변수 설정 (API 키):"
echo "   vi $SCRIPT_DIR/.env"
echo ""
echo "2. 재부팅 (I2C 권한 적용):"
echo "   sudo reboot"
echo ""
echo "3. 실행:"
echo "   cd $SCRIPT_DIR"
echo "   source .env"
echo "   ros2 launch no_ill_bringup no_ill_full.launch.py"
echo ""
echo "=========================================="
echo ""
