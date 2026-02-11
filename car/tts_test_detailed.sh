#!/bin/bash

echo "╔════════════════════════════════════════════════════╗"
echo "║         TTS 노드 상세 테스트 시작                 ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

source install/setup.bash

# 1단계: TTS 노드 시작
echo "[1/4] TTS 노드 시작 중..."
ros2 run tts tts_node > tts_run.log 2>&1 &
TTS_PID=$!
sleep 12

if ps -p $TTS_PID > /dev/null; then
    echo "✅ TTS 노드 실행 중 (PID: $TTS_PID)"
else
    echo "❌ TTS 노드 시작 실패"
    exit 1
fi

# 2단계: 현재 토픽 확인
echo ""
echo "[2/4] ROS2 토픽 확인..."
ros2 topic list 2>/dev/null | grep -E "tts|llm|is_chatting" | head -10

# 3단계: TTS 초기화 로그 확인
echo ""
echo "[3/4] TTS 초기화 로그 확인..."
grep -E "✅|★★★|OK" tts_run.log | head -20

# 4단계: 테스트 메시지 발행
echo ""
echo "[4/4] TTS 테스트 메시지 발행..."
sleep 2
echo "메시지 발행: '안녕하세요. 테스트입니다.'"
ros2 topic pub -1 /llm_response std_msgs/msg/String "{data: '안녕하세요. 테스트입니다.'}"
sleep 3

# 5단계: TTS 완료 토픽 확인
echo ""
echo "[5/5] TTS 완료 토픽 확인..."
timeout 5 ros2 topic echo /tts_done 2>/dev/null || echo "토픽 데이터 없음"

# 6단계: 노드 정보 출력
echo ""
echo "[6/5] TTS 노드 정보:"
ros2 node info /tts_node 2>/dev/null || echo "노드 정보 조회 실패"

# 정리
echo ""
echo "테스트 완료. TTS 노드 종료..."
kill $TTS_PID 2>/dev/null
wait $TTS_PID 2>/dev/null

echo "✅ TTS 테스트 완료"
