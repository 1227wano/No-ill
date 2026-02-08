#!/bin/bash

# 에러 발생 시 스크립트 중단
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 에러 트랩 설정
trap 'log_error "스크립트 실행 중 에러 발생 (라인: $LINENO)"; exit 1' ERR

log_info "========================================"
log_info "젯슨 오린 나노 ROS2 빌드 환경 설정 시작"
log_info "========================================"

# 1. 현재 시스템 정보 확인
log_info "시스템 정보 확인 중..."
free -h
df -h

# 2. 성능 모드 활성화
log_info "최대 성능 모드로 전환 중..."
if command -v jetson_clocks &> /dev/null; then
    sudo jetson_clocks
    log_info "jetson_clocks 활성화 완료"
else
    log_warning "jetson_clocks 명령어를 찾을 수 없습니다"
fi

if command -v nvpmodel &> /dev/null; then
    sudo nvpmodel -m 0
    log_info "전력 모드: MAXN (최대 성능)"
else
    log_warning "nvpmodel 명령어를 찾을 수 없습니다"
fi

# 3. 스왑 메모리 설정
SWAP_SIZE=8  # GB
SWAPFILE="/swapfile"

log_info "스왑 메모리 설정 중... (크기: ${SWAP_SIZE}GB)"

# 기존 스왑 파일 확인
if [ -f "$SWAPFILE" ]; then
    log_warning "기존 스왑 파일이 존재합니다. 제거 후 재생성합니다."
    sudo swapoff "$SWAPFILE" 2>/dev/null || true
    sudo rm -f "$SWAPFILE"
fi

# 스왑 파일 생성
log_info "스왑 파일 생성 중..."
sudo fallocate -l ${SWAP_SIZE}G "$SWAPFILE"
sudo chmod 600 "$SWAPFILE"
sudo mkswap "$SWAPFILE"
sudo swapon "$SWAPFILE"

# /etc/fstab에 영구 등록
if ! grep -q "$SWAPFILE" /etc/fstab; then
    log_info "스왑을 /etc/fstab에 영구 등록 중..."
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

log_info "스왑 메모리 설정 완료"
free -h

# 4. ROS2 의존성 확인 및 설치
log_info "ROS2 의존성 확인 중..."

ROS_DISTRO=${ROS_DISTRO:-humble}
log_info "ROS2 배포판: $ROS_DISTRO"

if [ ! -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
    log_error "ROS2 $ROS_DISTRO가 설치되지 않았습니다"
    log_error "/opt/ros/$ROS_DISTRO/setup.bash를 찾을 수 없습니다"
    exit 1
fi

# 필수 패키지 설치
log_info "필수 패키지 설치 중..."
sudo apt update
sudo apt install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-$ROS_DISTRO-navigation2 \
    ros-$ROS_DISTRO-nav2-bringup \
    ros-$ROS_DISTRO-twist-mux \
    python3-pip

# Python 의존성 설치
log_info "Python 의존성 설치 중..."
pip3 install --upgrade pip
pip3 install onnxruntime opencv-python numpy

# jtop 설치 (리소스 모니터링용)
if ! command -v jtop &> /dev/null; then
    log_info "jetson-stats(jtop) 설치 중..."
    sudo -H pip3 install -U jetson-stats
    log_info "jtop 설치 완료. 재부팅 후 사용 가능합니다"
fi

log_info "========================================"
log_info "젯슨 환경 설정 완료!"
log_info "========================================"
log_info "다음 단계: ROS2 워크스페이스 빌드를 진행하세요"
log_info "실행 명령: ./build_workspace.sh"
