#!/bin/bash

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 배너
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ROS2 NOIL 시스템 대화형 테스트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 환경 설정
source install/setup.bash

# 메뉴
show_menu() {
    echo ""
    echo -e "${YELLOW}테스트 메뉴:${NC}"
    echo "1. STT 노드 테스트"
    echo "2. TTS 노드 테스트"
    echo "3. YOLO 감지 노드 테스트"
    echo "4. 토픽 모니터링"
    echo "5. 실시간 대화 시나리오"
    echo "6. 전체 시스템 시작"
    echo "0. 종료"
    echo ""
}

# 1. STT 테스트
test_stt() {
    log_step "STT 노드 테스트 시작..."
    log_info "마이크가 연결되어 있는지 확인하세요."
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    log_info "STT 노드 실행 중... (30초 후 자동 종료)"
    timeout 30 ros2 run stt stt_node
    log_success "STT 테스트 완료"
}

# 2. TTS 테스트
test_tts() {
    log_step "TTS 노드 테스트 시작..."
    log_info "스피커가 연결되어 있는지 확인하세요."
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    log_info "TTS 노드 실행 중... (10초 후 자동 종료)"
    timeout 10 ros2 run tts tts_node
    log_success "TTS 테스트 완료"
}

# 3. YOLO 테스트
test_yolo() {
    log_step "YOLO 감지 노드 테스트 시작..."
    log_info "카메라가 연결되어 있는지 확인하세요."
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    log_info "YOLO 노드 실행 중... (10초 후 자동 종료)"
    timeout 10 ros2 run yolo_detector detect_node
    log_success "YOLO 테스트 완료"
}

# 4. 토픽 모니터링
monitor_topics() {
    log_step "토픽 모니터링 시작..."
    echo ""
    echo "선택하세요:"
    echo "1. 감지 객체 타입 (/object_type)"
    echo "2. 사람 위치 (/person_x, /person_y)"
    echo "3. 대화 상태 (/is_chatting)"
    echo "4. 전체 토픽 목록"
    read -p "선택: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            log_info "감지 객체 타입 모니터링... (Ctrl+C로 종료)"
            ros2 topic echo /object_type
            ;;
        2)
            log_info "사람 위치 모니터링... (Ctrl+C로 종료)"
            ros2 topic echo /person_x &
            ros2 topic echo /person_y
            ;;
        3)
            log_info "대화 상태 모니터링... (Ctrl+C로 종료)"
            ros2 topic echo /is_chatting
            ;;
        4)
            log_info "전체 토픽 목록:"
            ros2 topic list
            ;;
    esac
}

# 5. 대화 시나리오
scenario_demo() {
    log_step "대화 시나리오 데모 시작..."
    echo ""
    echo "시나리오:"
    echo "1. 로봇이 순찰 중 '노일아'라고 호출"
    echo "2. 로봇이 정지하고 '네, 말씀하세요' 응답"
    echo "3. 7초 이내에 질문하면 응답"
    echo "4. 응답 없으면 '대화를 종료합니다' 출력"
    echo ""
    read -p "데모를 시작하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    log_info "STT + TTS 노드 시작..."
    ros2 run stt stt_node &
    STT_PID=$!
    
    sleep 2
    
    ros2 run tts tts_node &
    TTS_PID=$!
    
    log_info "노드 실행 중... 핫워드를 말해보세요!"
    log_info "예시: '노일아, 오늘 날씨는?'"
    log_info "(30초 후 자동 종료됩니다)"
    
    sleep 30
    
    kill $STT_PID $TTS_PID 2>/dev/null
    log_success "데모 완료"
}

# 6. 전체 시스템 시작
start_system() {
    log_step "전체 시스템 시작..."
    echo ""
    echo "선택하세요:"
    echo "1. Launch 파일로 시작 (권장)"
    echo "2. 백그라운드 실행"
    echo "3. tmux 세션으로 시작"
    read -p "선택: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            log_info "Launch 파일 실행... (Ctrl+C로 종료)"
            ros2 launch no_ill_bringup noil_system.launch.py
            ;;
        2)
            log_info "백그라운드로 실행..."
            nohup ros2 launch no_ill_bringup noil_system.launch.py > noil.log 2>&1 &
            log_success "백그라운드 실행 완료 (PID: $!)"
            log_info "로그 확인: tail -f noil.log"
            ;;
        3)
            log_info "tmux 세션으로 시작..."
            if ! command -v tmux &> /dev/null; then
                log_error "tmux가 설치되지 않았습니다. 설치하시겠습니까? (y/N)"
                read -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sudo apt-get install -y tmux
                fi
            else
                tmux new-session -d -s noil -c "$(pwd)" \
                    "source install/setup.bash && ros2 launch no_ill_bringup noil_system.launch.py"
                log_success "tmux 세션 생성 완료"
                log_info "명령어: tmux attach -t noil"
            fi
            ;;
    esac
}

# 메인 루프
while true; do
    show_menu
    read -p "선택: " -n 1 -r
    echo
    
    case $REPLY in
        1) test_stt ;;
        2) test_tts ;;
        3) test_yolo ;;
        4) monitor_topics ;;
        5) scenario_demo ;;
        6) start_system ;;
        0) 
            log_info "종료합니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            ;;
    esac
done
