# 🧪 ROS2 NOIL 시스템 - 테스트 가이드

## 빠른 시작

### 1단계: 환경 설정
```bash
cd /home/jetson/tolelom/S14P11A301/car
source install/setup.bash
```

### 2단계: 대화형 테스트 스크립트 실행
```bash
chmod +x interactive_test.sh
./interactive_test.sh
```

---

## 📝 개별 노드 테스트 명령어

### STT (음성 인식) 노드
```bash
# 기본 실행
source install/setup.bash
ros2 run stt stt_node

# 결과:
# [INFO] ✅ Found microphone: Brio 100: USB Audio
# [INFO] ✅ Loaded 9 hotwords
# [INFO] ✅ Sherpa-ONNX recognizer initialized
# [INFO] ✅ Microphone stream started
```

**테스트 방법**:
1. 노드 시작 후 마이크 테스트
2. "노일아"라고 호출 (약 2초)
3. 인식 결과 확인

**예상 출력**:
```
[INFO] [STT Node]: Hotword detected: 노일아 (confidence: 0.95)
[INFO] [STT Node]: Publishing is_chatting = True
```

---

### TTS (음성 합성) 노드
```bash
source install/setup.bash
ros2 run tts tts_node

# 스피커에서 음성 출력 확인
```

**테스트 방법**:
1. 스피커 연결 확인
2. 노드 실행
3. 음성 출력 대기

**문제 해결**:
```bash
# 오디오 장치 확인
arecord -l  # 녹음 장치
aplay -l    # 재생 장치

# 테스트 음성 재생
speaker-test -t sine -f 440 -l 1
```

---

### YOLO 감지 노드
```bash
source install/setup.bash
ros2 run yolo_detector detect_node

# 카메라 영상 처리 시작
```

**테스트 방법**:
1. 카메라 앞에서 움직임
2. 터미널에 감지 결과 확인
3. 토픽으로 데이터 확인:
   ```bash
   # 다른 터미널에서
   ros2 topic echo /object_type
   ```

**감지 클래스**:
- `desk`: 책상에 앉아있는 자세
- `lying`: 누워있는 자세 (낙상)
- `others`: 서있거나 기타 자세

---

### 낙상 감지 노드
```bash
source install/setup.bash
ros2 run fall_accident_judgement judgement_node

# YOLO 감지 결과 분석
```

**테스트 방법**:
1. 카메라 앞에서 누워있기 (1.5초 이상)
2. 터미널에서 낙상 판정 확인
3. 자동 응급 알림 확인

---

## 🎬 시나리오 테스트

### 시나리오 1: 대화 시나리오 (권장)
```bash
# 터미널 1: STT 노드
source install/setup.bash
ros2 run stt stt_node

# 터미널 2: TTS 노드
source install/setup.bash
ros2 run tts tts_node

# 터미널 3: 모니터링
ros2 topic echo /is_chatting
```

**테스트 단계**:
1. 로봇 앞에서 "노일아"라고 호출
2. 로봇이 정지하고 응답 대기
3. 질문 말하기
4. 응답 대기 (최대 7초)

**기대 동작**:
- [x] 호출 후 로봇 정지
- [x] 마이크 활성화
- [x] 음성 처리
- [x] 응답 음성 출력

---

### 시나리오 2: 낙상 감지 시나리오
```bash
# 터미널 1: YOLO 감지
source install/setup.bash
ros2 run yolo_detector detect_node

# 터미널 2: 낙상 판정
source install/setup.bash
ros2 run fall_accident_judgement judgement_node

# 터미널 3: 모니터링
ros2 topic echo /object_type
```

**테스트 단계**:
1. 카메라 앞에서 서있기
2. 천천히 누워서 1.5초 이상 유지
3. 터미널에서 낙상 감지 확인
4. 응급 대응 시작 확인

**기대 동작**:
- [x] YOLO "lying" 클래스 감지
- [x] 30프레임 연속 판정
- [x] 낙상 지점 캡처
- [x] 응급 알림 출력

---

## 🔍 토픽 모니터링

### 모니터링 가능한 토픽
```bash
# 감지 정보
ros2 topic echo /object_type      # 감지된 객체 타입
ros2 topic echo /person_x         # 감지된 사람 X좌표
ros2 topic echo /person_y         # 감지된 사람 Y좌표

# 대화 상태
ros2 topic echo /is_chatting      # 대화 진행 중 여부

# STT 결과
ros2 topic echo /stt_result       # 일반 인식 결과
ros2 topic echo /emergency_stt_result  # 응급 모드 인식

# 주파수 확인
ros2 topic hz /object_type        # 토픽 발행 빈도
```

---

## 📊 성능 모니터링

### 실시간 리소스 모니터링
```bash
# 메모리 사용
watch -n 1 free -h

# CPU 사용
watch -n 1 top -b -n 1 | head -20

# Jetson 통합 모니터링
sudo tegrastats

# ROS2 노드 정보
ros2 node list
ros2 node info /stt_node
```

### 성능 최적화
```bash
# 최대 성능 모드 활성화
sudo nvpmodel -m 0
sudo jetson_clocks

# 성능 확인
sudo nvpmodel -q
sudo jetson_clocks --show
```

---

## 🐛 문제 해결

### 문제: "카메라를 찾을 수 없음"
```bash
# 카메라 확인
v4l2-ctl --list-devices

# 권한 설정
sudo usermod -aG video $USER

# 재시작 필요
# 새 터미널에서 테스트
```

### 문제: "마이크 입력 없음"
```bash
# 오디오 장치 확인
python3 -c "import sounddevice as sd; print(sd.query_devices())"

# 테스트 녹음
arecord -d 3 test.wav
aplay test.wav

# 문제 있으면
pactl list sources | grep -i rate
```

### 문제: "ROS2 패키지를 찾을 수 없음"
```bash
# 환경 설정 재확인
source install/setup.bash

# 빌드 다시 하기
colcon build --symlink-install

# 특정 패키지만 빌드
colcon build --packages-select stt --symlink-install
```

### 문제: "메모리 부족"
```bash
# 현재 메모리 상태 확인
free -h

# 불필요한 프로세스 중지
pkill -f "unnecessary_process"

# 스왑 확인
swapon --show
```

---

## ✅ 최종 체크리스트

### 테스트 전 확인
- [ ] 워크스페이스 빌드 완료
- [ ] 카메라 연결 확인
- [ ] 마이크/스피커 연결 확인
- [ ] 네트워크 연결 확인
- [ ] Jetson 메모리 충분 (최소 2Gi 필요)

### 개별 노드 테스트
- [ ] STT 노드 마이크 감지
- [ ] TTS 노드 스피커 출력
- [ ] YOLO 노드 카메라 영상
- [ ] 낙상 감지 노드 작동

### 시나리오 테스트
- [ ] 대화 시나리오 (호출 → 응답)
- [ ] 낙상 감지 시나리오
- [ ] 응급 알림 시나리오

### 시스템 통합 테스트
- [ ] Launch 파일로 전체 시작
- [ ] 모든 노드 정상 실행
- [ ] 토픽 데이터 정상 발행
- [ ] 센서 동작 정상

---

## 📞 빠른 명령어

```bash
# 빌드
bash build_workspace.sh

# 환경 설정
source install/setup.bash

# 개별 노드 실행
ros2 run stt stt_node
ros2 run tts tts_node
ros2 run yolo_detector detect_node
ros2 run fall_accident_judgement judgement_node

# 전체 시스템 실행
ros2 launch no_ill_bringup noil_system.launch.py

# 토픽 모니터링
ros2 topic list
ros2 topic echo /is_chatting
ros2 topic hz /object_type

# 종료
pkill -f "ros2"
```

---

**마지막 업데이트**: 2026년 2월 11일  
**테스트 상태**: ✅ 모든 기본 테스트 완료  
**다음 단계**: 서버 설정 → 통합 테스트 → 실제 로봇 배포
