#!/bin/bash

# =============================================================================
# Jetson Orin Nano 유사 환경 구축 (WSL2 Ubuntu)
# -----------------------------------------------------------------------------
# 주의: x86_64 GPU 환경입니다. 실제 Jetson과 GPU 성능이 다릅니다.
#       CPU/메모리 부하는 참고 가능하지만, GPU 부하는 정확하지 않습니다.
# =============================================================================

set -e

# 스크립트 실행 위치 자동 감지
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo " Jetson Orin Nano 유사 환경 구축 스크립트"
echo "=========================================="
echo "작업 디렉토리: $SCRIPT_DIR"

# 1. Docker 설치
echo "[1/5] Docker 설치..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "⚠️  Docker 그룹 적용을 위해 터미널을 재시작 후 스크립트를 다시 실행하세요."
    echo "   또는: newgrp docker && $0"
    exit 0
else
    echo "Docker가 이미 설치되어 있습니다."
fi

# 2. NVIDIA Container Toolkit
echo "[2/5] NVIDIA Container Toolkit 설치..."
if ! dpkg -l | grep -q nvidia-container-toolkit; then
    distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo service docker restart
else
    echo "NVIDIA Container Toolkit이 이미 설치되어 있습니다."
fi

# 3. GPU 테스트
echo "[3/5] GPU 연결 테스트..."
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi || {
    echo "❌ GPU 연결 실패. NVIDIA 드라이버를 확인하세요."
    exit 1
}

# 4. 이미지 pull
echo "[4/5] CUDA 개발 이미지 다운로드..."
docker pull nvidia/cuda:12.0.0-cudnn8-devel-ubuntu22.04

# 5. 컨테이너 생성 (Jetson Orin Nano 리소스 제한 적용)
echo "[5/5] 컨테이너 생성..."
docker rm -f jetson-sim 2>/dev/null || true
docker run -d \
    --name jetson-sim \
    --cpus="6.0" \
    --memory="8g" \
    --memory-swap="8g" \
    --shm-size="4g" \
    --gpus all \
    -e CUDA_MEMORY_FRACTION=0.375 \
    -e PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
    -e TF_GPU_ALLOCATOR=cuda_malloc_async \
    -e TF_FORCE_GPU_ALLOW_GROWTH=true \
    -p 8080:8080 \
    -v "$SCRIPT_DIR":/workspace \
    nvidia/cuda:12.0.0-cudnn8-devel-ubuntu22.04 \
    tail -f /dev/null

echo ""
echo "=========================================="
echo " 설치 완료!"
echo "=========================================="
echo ""
echo "컨테이너 접속: docker exec -it jetson-sim bash"
echo ""
echo "⚠️  리소스 제한 (Jetson Orin Nano 기준):"
echo "   - CPU: 6 코어"
echo "   - 메모리: 8GB"
echo "   - GPU: 호스트 GPU 사용 (성능은 Jetson과 다름)"
echo ""

# ROS2 설치 가이드
cat << 'EOF'
------------------------------------------
 컨테이너 내부에서 ROS2 설치 방법:
------------------------------------------
docker exec -it jetson-sim bash

# 필수 패키지
apt update && apt install -y curl gnupg lsb-release

# ROS2 저장소 추가
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list

# ROS2 Humble 설치
apt update && apt install -y ros-humble-desktop
source /opt/ros/humble/setup.bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

# 확인
ros2 doctor
EOF
