#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "사용법: $0 <패키지명> [패키지명2 ...]"
    echo ""
    echo "예시:"
    echo "  $0 yolo_detector"
    echo "  $0 patrol_pkg pca_drive"
    exit 1
fi

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$WORKSPACE_ROOT"

ROS_DISTRO=${ROS_DISTRO:-humble}
source /opt/ros/$ROS_DISTRO/setup.bash

echo -e "${GREEN}패키지 재빌드 중: $@${NC}"

colcon build \
    --packages-select "$@" \
    --parallel-workers 2 \
    --cmake-args -DCMAKE_BUILD_TYPE=Release \
    --symlink-install

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 빌드 성공!${NC}"
    echo ""
    echo "환경 재로드:"
    echo "  source install/setup.bash"
else
    echo -e "${YELLOW}빌드 실패${NC}"
    exit 1
fi
