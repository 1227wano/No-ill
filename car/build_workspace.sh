#!/bin/bash

# 에러 발생 시 스크립트 중단
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 에러 트랩 설정
trap 'log_error "빌드 중 에러 발생 (라인: $LINENO)"; exit 1' ERR

# 워크스페이스 디렉토리 확인
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_info "워크스페이스 경로: $WORKSPACE_ROOT"

if [ ! -d "$WORKSPACE_ROOT/src" ]; then
    log_error "src 디렉토리를 찾을 수 없습니다"
    log_error "현재 위치: $WORKSPACE_ROOT"
    exit 1
fi

cd "$WORKSPACE_ROOT"

# ROS2 환경 소싱
ROS_DISTRO=${ROS_DISTRO:-humble}
log_info "ROS2 환경 로드 중... (배포판: $ROS_DISTRO)"
source /opt/ros/$ROS_DISTRO/setup.bash

log_info "========================================"
log_info "ROS2 워크스페이스 빌드 시작"
log_info "========================================"

# 빌드 설정
PARALLEL_JOBS=2  # 오린 나노는 메모리 제약 고려
BUILD_TYPE="Release"

log_info "빌드 설정:"
log_info "  - 병렬 작업 수: $PARALLEL_JOBS"
log_info "  - 빌드 타입: $BUILD_TYPE"
log_info "  - 워크스페이스: $WORKSPACE_ROOT"

# 이전 빌드 정리 (선택사항)
read -p "이전 빌드를 정리하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_warning "이전 빌드 정리 중..."
    rm -rf build/ install/ log/
    log_info "정리 완료"
fi

# Python 캐시 정리
log_step "Python 캐시 정리 중..."
find src -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find src -type f -name "*.pyc" -delete 2>/dev/null || true
log_info "Python 캐시 정리 완료"

# rosdep 업데이트 및 의존성 설치
log_step "rosdep 의존성 확인 중..."
if ! rosdep update 2>/dev/null; then
    log_warning "rosdep 업데이트 실패. sudo로 재시도..."
    sudo rosdep init 2>/dev/null || true
    rosdep update
fi

log_info "의존성 설치 중..."
rosdep install --from-paths src --ignore-src -r -y || log_warning "일부 의존성 설치 실패 (계속 진행)"

# 메모리 모니터링 함수
monitor_resources() {
    while true; do
        clear
        echo "=== 실시간 리소스 모니터링 ==="
        free -h | head -2
        echo ""
        echo "Ctrl+C로 중지"
        sleep 2
    done
}

# 백그라운드에서 리소스 모니터링 시작 여부 확인
read -p "백그라운드에서 리소스 모니터링을 시작하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "다른 터미널에서 'watch -n 1 free -h' 실행을 권장합니다"
fi

# 1단계: C++ 패키지 빌드
log_step "1단계: C++ 제어 노드 빌드 중..."
colcon build \
    --packages-select \
        chat_stop_gate \
        keyboard_latch_cpp \
        patrol_pkg \
        pca_drive \
        person_override_pkg \
        safety_override_pkg \
    --parallel-workers $PARALLEL_JOBS \
    --cmake-args -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    --symlink-install

if [ $? -eq 0 ]; then
    log_info "✓ C++ 제어 노드 빌드 성공"
else
    log_error "C++ 제어 노드 빌드 실패"
    exit 1
fi

# 2단계: Python 패키지 빌드
log_step "2단계: Python 패키지 빌드 중..."
colcon build \
    --packages-select \
        llm \
        stt \
        tts \
        emergency_response \
        upload_accident \
        fall_accident_judgement \
        yolo_detector \
    --parallel-workers $PARALLEL_JOBS \
    --symlink-install

if [ $? -eq 0 ]; then
    log_info "✓ Python 패키지 빌드 성공"
else
    log_error "Python 패키지 빌드 실패"
    exit 1
fi

# 3단계: Bringup 패키지 빌드
log_step "3단계: Bringup 패키지 빌드 중..."
colcon build \
    --packages-select \
        no_ill_bringup \
        robot_bringup \
    --parallel-workers $PARALLEL_JOBS \
    --symlink-install

if [ $? -eq 0 ]; then
    log_info "✓ Bringup 패키지 빌드 성공"
else
    log_error "Bringup 패키지 빌드 실패"
    exit 1
fi

# 4단계: 드라이버 패키지 빌드 (있는 경우)
log_step "4단계: 드라이버 패키지 확인 중..."
DRIVER_PACKAGES=""

if [ -d "src/drivers/ydlidar_ros2_driver" ] && [ -f "src/drivers/ydlidar_ros2_driver/package.xml" ]; then
    DRIVER_PACKAGES="$DRIVER_PACKAGES ydlidar_ros2_driver"
    log_info "ydlidar_ros2_driver 발견"
fi

if [ -d "src/drivers/rf2o_laser_odometry" ] && [ -f "src/drivers/rf2o_laser_odometry/package.xml" ]; then
    DRIVER_PACKAGES="$DRIVER_PACKAGES rf2o_laser_odometry"
    log_info "rf2o_laser_odometry 발견"
fi

if [ -n "$DRIVER_PACKAGES" ]; then
    log_info "드라이버 빌드 중: $DRIVER_PACKAGES"
    colcon build \
        --packages-select $DRIVER_PACKAGES \
        --parallel-workers $PARALLEL_JOBS \
        --cmake-args -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
        --symlink-install

    if [ $? -eq 0 ]; then
        log_info "✓ 드라이버 패키지 빌드 성공"
    else
        log_warning "드라이버 패키지 빌드 실패 (계속 진행)"
    fi
else
    log_warning "빌드할 드라이버 패키지가 없습니다"
fi

log_info "========================================"
log_info "빌드 완료!"
log_info "========================================"

# 환경 설정 안내
log_info "다음 명령어로 환경을 설정하세요:"
echo ""
echo "  source $WORKSPACE_ROOT/install/setup.bash"
echo ""
log_info "또는 ~/.bashrc에 추가:"
echo ""
echo "  echo 'source $WORKSPACE_ROOT/install/setup.bash' >> ~/.bashrc"
echo ""

# 빌드 결과 요약
log_step "빌드 요약:"
colcon list 2>/dev/null || log_warning "패키지 목록을 가져올 수 없습니다"

log_info "테스트 실행 (선택사항):"
echo "  colcon test"
echo "  colcon test-result --verbose"

exit 0
