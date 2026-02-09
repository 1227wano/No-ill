# 🤖 NOIL (No One Is Left)

> 독거노인을 위한 자율주행 AI 반려로봇

![ROS2](https://img.shields.io/badge/ROS2-Humble-blue)
![Python](https://img.shields.io/badge/Python-3.8+-green)
![C++](https://img.shields.io/badge/C++-17-orange)
![TensorRT](https://img.shields.io/badge/TensorRT-8.x-red)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 목차

- [프로젝트 소개](#-프로젝트-소개)
- [핵심 기능](#-핵심-기능)
- [시스템 아키텍처](#️-시스템-아키텍처)
- [노드 구성](#-노드-구성)
- [설치 및 실행](#-설치-및-실행)
- [시나리오](#-시나리오)
- [성능 지표](#-성능-지표)
- [개발팀](#-개발팀)

---

## 🎯 프로젝트 소개

**NOIL(No One Is Left)**은 독거노인의 안전을 지키는 자율주행 반려로봇입니다.

### 주요 목표
- ✅ 실내 자율 순찰로 사고 조기 발견
- ✅ AI 음성 대화로 정서적 교감
- ✅ 낙상 자동 감지 및 응급 대응
- ✅ 자동 신고로 골든타임 확보

---

## 🚀 핵심 기능

### 1. 자율 순찰
- 웨이포인트 기반 실내 순회
- 사람 발견 시 자동 추적
- 장애물 회피 (Nav2)

### 2. 낙상 감지
- TensorRT 최적화 YOLO 객체 감지
- 30프레임 연속 분석으로 오탐 방지
- 1.5초 내 낙상 판단

### 3. 응급 대응
- 낙상 지점 자동 주행
- "괜찮습니까?" 최대 5회 확인
- 무응답 시 자동 캡처 + 신고

### 4. AI 대화
- 핫워드 기반 대화 시작 ("노일아")
- LLM 기반 자연스러운 대화
- 한국어 음성 인식/합성 (Sherpa-ONNX)

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    NOIL System Overview                     │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   Camera    │ ──→ YOLO Detection (TensorRT)
    │   (Brio)    │         ↓
    └─────────────┘    Object Type
                            ↓
    ┌─────────────┐    Fall Judgement
    │ Microphone  │         ↓
    │   (Brio)    │ ──→ Emergency Response
    └─────────────┘         ↓
                       ┌─────────┐
    ┌─────────────┐    │ Nav2 +  │
    │   Speaker   │←── │twist_mux│ ──→ Robot Control
    │  (UACDemo)  │    └─────────┘
    └─────────────┘         ↑
                       AI Layer (STT/LLM/TTS)
```

### 계층 구조

```
┌──────────────────┐
│  Perception      │  YOLO 감지, 낙상 판단
└────────┬─────────┘
         ↓
┌──────────────────┐
│  Navigation      │  웨이포인트 순회, 낙상 지점 주행
└────────┬─────────┘
         ↓
┌──────────────────┐
│  Control         │  twist_mux 우선순위 제어
│  ┌────────────┐  │
│  │ Priority   │  │  300: 대화 중 정지
│  │ 300→50→10  │  │   50: 사람 추적
│  └────────────┘  │   10: Nav2 자율주행
└────────┬─────────┘
         ↓
    ┌─────────┐
    │  Robot  │
    └─────────┘

┌──────────────────┐
│  Emergency       │  응급 대응, 이미지 업로드
└──────────────────┘

┌──────────────────┐
│  AI              │  STT, LLM, TTS
└──────────────────┘
```

---

## 📦 노드 구성

### Perception (인식)

| 노드 | 언어 | 설명 |
|------|------|------|
| **yolo_detector** | Python | TensorRT YOLO 객체 감지 (20 FPS) |
| **fall_judgement** | Python | 낙상 판단 (30프레임 연속) |

### Navigation (주행)

| 노드 | 언어 | 설명 |
|------|------|------|
| **waypoint_follower** | C++ | 웨이포인트 순회 |
| **fall_point_navigator** | C++ | 낙상 지점 자동 주행 |

### Control (제어)

| 노드 | 언어 | 설명 |
|------|------|------|
| **person_override** | C++ | 사람 추적 (우선순위 50) |
| **chat_stop_gate** | C++ | 대화 중 정지 (우선순위 300) |

### Emergency (응급)

| 노드 | 언어 | 설명 |
|------|------|------|
| **emergency_response** | Python | 응급 대응 시퀀스 |
| **upload_accident** | Python | 사고 이미지 서버 업로드 |

### AI (인공지능)

| 노드 | 언어 | 설명 |
|------|------|------|
| **llm** | Python | LLM 서버 통신 (JWT 인증) |
| **stt** | Python | 음성 인식 (Sherpa-ONNX) |
| **tts** | Python | 음성 합성 (Sherpa-ONNX) |

---

## 🔄 주요 토픽

### 인식 관련
- `/person_x`, `/person_y` (Int32) - 사람 좌표
- `/object_type` (String) - "lying", "others"
- `/check_accident` (Bool) - 낙상 여부 확인 명령

### 주행 관련
- `/cmd_vel` (Twist) - Nav2 명령
- `/cmd_vel_person` (Twist) - 사람 추적 명령
- `/cmd_vel_is_chatting` (Twist) - 정지 명령
- `/fall_arrived` (Bool) - 낙상 지점 도착

### AI 관련
- `/is_chatting` (Bool) - 대화 상태
- `/stt_result` (String) - 음성 인식 결과
- `/llm_response` (String) - LLM 응답
- `/tts_trigger` (String) - TTS 트리거
- `/tts_done`, `/emergency_tts_done` (Bool) - TTS 완료

### 응급 관련
- `/force_listen` (Bool) - STT 강제 청취
- `/capture_command` (Bool) - 캡처 명령
- `/accident_cap` (Bool) - 캡처 완료

---

## 🛠️ 설치 및 실행

### 시스템 요구사항

- **OS**: Ubuntu 22.04
- **ROS**: ROS2 Humble
- **하드웨어**: 
  - NVIDIA Jetson (TensorRT 지원)
  - Logitech Brio (카메라 + 마이크)
  - UACDemo 스피커

### 의존성 설치

```bash
# ROS2 패키지
sudo apt install ros-humble-desktop
sudo apt install ros-humble-nav2-bringup
sudo apt install ros-humble-navigation2
sudo apt install ros-humble-twist-mux

# Python 패키지
pip3 install requests numpy sounddevice
pip3 install sherpa-onnx pycuda

# TensorRT (Jetson JetPack에 포함)
```

### 빌드

```bash
cd ~/ros2_ws
colcon build --packages-select \
  yolo_detector \
  fall_accident_judgement \
  waypoint_follower \
  fall_point_navigator \
  person_override \
  chat_stop_gate \
  emergency_response \
  upload_accident \
  llm stt tts \
  no_ill_bringup

source install/setup.bash
```

### 실행

```bash
# 전체 시스템 실행
ros2 launch no_ill_bringup noil_system.launch.py

# 개별 노드 테스트
ros2 run yolo_detector detector_node
ros2 run stt stt_node
ros2 run tts tts_node
```

### 설정 파일

**웨이포인트 설정** (`config/waypoints.yaml`):
```yaml
waypoints:
  - {x: 1.0, y: 2.0}
  - {x: 3.0, y: 4.0}
  - {x: 5.0, y: 1.0}
```

**핫워드 설정** (`config/hotwords.txt`):
```
노일아:2.0
노일:1.5
로봇:1.0
```

**twist_mux 설정** (`config/twist_mux.yaml`):
```yaml
topics:
  - name: cmd_vel_is_chatting
    topic: /cmd_vel_is_chatting
    timeout: 0.5
    priority: 300  # 최고 우선순위

  - name: cmd_vel_person
    topic: /cmd_vel_person
    timeout: 0.5
    priority: 50   # 중간 우선순위

  - name: cmd_vel
    topic: /cmd_vel
    timeout: 0.5
    priority: 10   # 기본 우선순위
```

---

## 🎬 시나리오

### 시나리오 1: 정상 순찰 + 대화

```
1. 웨이포인트 A → B → C 순회
   ↓
2. 사람 감지 → 자동 추적
   ↓
3. 사용자: "노일아"
   ↓
4. 로봇 정지 + TTS: "네, 말씀하세요"
   ↓
5. 사용자: "오늘 날씨 어때?"
   ↓
6. STT → LLM → TTS: "오늘은 맑고 화창합니다"
   ↓
7. 7초 타임아웃 또는 종료
   ↓
8. TTS: "대화를 종료합니다"
   ↓
9. 웨이포인트 순회 재개
```

### 시나리오 2: 낙상 감지 + 응급 대응

```
1. YOLO: "lying" 감지 시작
   ↓
2. 30프레임 연속 (1.5초) → 낙상 확정
   ↓
3. 현재 위치 저장 + 낙상 지점 주행
   ↓
4. 도착 → 주행 정지
   ↓
5. TTS: "괜찮습니까?" (1차)
   ↓
6. 5초 대기
   ↓
7-A. 사용자: "응" → TTS: "네, 괜찮으시군요!" → 복귀
   ↓
7-B. 무응답 → 2차 질문 (최대 5회)
   ↓
8. 5회 무응답
   ↓
9. 캡처 (N0111.jpg) + 서버 업로드
   ↓
10. TTS: "신고를 완료했습니다"
   ↓
11. 1시간 쿨다운
   ↓
12. 웨이포인트 순회 재개
```

---

## 📈 성능 지표

| 항목 | 수치 | 비고 |
|------|------|------|
| **YOLO 추론** | 20 FPS | TensorRT FP16 최적화 |
| **낙상 감지** | 1.5초 | 30프레임 @ 20Hz |
| **STT 반응** | ~0.5초 | 핫워드 감지 시간 |
| **LLM 응답** | 2-3초 | 서버 의존 |
| **TTS 재생** | 0.9배속 | 자연스러운 발화 |
| **응급 대응** | ~10초 | 도착 후 첫 질문까지 |
| **메모리 사용** | ~2GB | Jetson Nano 기준 |

---

## 🎯 기술적 특징

### 1. 성능 최적화
- ✅ TensorRT FP16 양자화 (Jetson)
- ✅ PyCUDA 직접 메모리 관리
- ✅ 객체 트래킹으로 ID 재사용
- ✅ 비동기 AI 처리

### 2. 안정성
- ✅ 재시도 로직 (토큰, 업로드)
- ✅ 타임아웃 처리 (모든 네트워크 요청)
- ✅ 예외 처리 및 상세 로그
- ✅ 쿨다운으로 과부하 방지

### 3. 모듈화
- ✅ 11개 독립 노드
- ✅ 명확한 토픽 인터페이스
- ✅ 파라미터 기반 설정
- ✅ 계층적 아키텍처

### 4. 실시간성
- ✅ 20Hz YOLO 추론
- ✅ 10Hz 제어 루프
- ✅ twist_mux 우선순위 제어
- ✅ 비동기 음성 처리

---

## 🔧 디렉토리 구조

```
ros2_ws/src/
├── perception/
│   ├── yolo_detector/
│   │   ├── yolo_detector/
│   │   │   └── detector_node.py
│   │   ├── models/
│   │   │   └── best.engine
│   │   └── package.xml
│   └── fall_accident_judgement/
│       └── fall_accident_judgement/
│           └── judgement_node.py
│
├── navigation/
│   ├── waypoint_follower/
│   │   ├── src/
│   │   │   └── waypoint_follower_node.cpp
│   │   └── config/
│   │       └── waypoints.yaml
│   └── fall_point_navigator/
│       └── src/
│           └── fall_point_navigator_node.cpp
│
├── control/
│   ├── person_override/
│   │   └── src/
│   │       └── person_override_node.cpp
│   └── chat_stop_gate/
│       └── src/
│           └── chat_stop_gate_node.cpp
│
├── emergency_response/
│   └── emergency_response/
│       └── emergency_response_node.py
│
├── upload_accident/
│   └── upload_accident/
│       └── upload_accident_node.py
│
├── llm/
│   └── llm/
│       └── llm_node.py
│
├── stt/
│   ├── stt/
│   │   └── stt_node.py
│   └── config/
│       └── hotwords.txt
│
├── tts/
│   ├── tts/
│   │   └── tts_node.py
│   └── models/
│       ├── tts_model.onnx
│       └── tokens.txt
│
└── core/
    └── no_ill_bringup/
        ├── launch/
        │   └── noil_system.launch.py
        └── config/
            ├── twist_mux.yaml
            └── nav2_params.yaml
```

---

## 🐛 트러블슈팅

### YOLO 감지 안 됨
```bash
# 카메라 확인
v4l2-ctl --list-devices

# 권한 확인
sudo usermod -aG video $USER

# TensorRT 엔진 재생성
trtexec --onnx=best.onnx --saveEngine=best.engine --fp16
```

### 음성 인식 안 됨
```bash
# 마이크 확인
python3 -c "import sounddevice as sd; print(sd.query_devices())"

# 샘플레이트 확인
pactl list sources | grep -i rate
```

### Nav2 주행 안 됨
```bash
# 맵 확인
ros2 topic echo /map

# TF 확인
ros2 run tf2_tools view_frames

# Nav2 로그 확인
ros2 launch nav2_bringup navigation_launch.py log_level:=debug
```

---

## 📚 참고 자료

- [ROS2 Humble Documentation](https://docs.ros.org/en/humble/)
- [Nav2 Documentation](https://navigation.ros.org/)
- [Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx)
- [TensorRT](https://developer.nvidia.com/tensorrt)
- [YOLOv11](https://docs.ultralytics.com/)

---

## 👥 개발팀

**SSAFY 14기 임베디드 트랙 - A301팀**

| 역할 | 담당자 | 주요 업무 |
|------|--------|----------|
| 팀장 / 임베디드 | - | 로봇 제어, ROS2 아키텍처 |
| 임베디드 | - | YOLO 최적화, 낙상 감지 |
| 임베디드 | - | AI 통신, STT/TTS |
| 백엔드 | - | LLM 서버, API 개발 |
| 프론트엔드 | - | 관리자 웹 대시보드 |

**프로젝트 기간**: 2026년 1월 ~ 2월 (6주)

---

## 📄 라이선스

MIT License

Copyright (c) 2026 SSAFY A301 Team

---

## 🙏 감사의 말

이 프로젝트는 SSAFY(삼성 청년 SW 아카데미) 14기 임베디드 트랙 특화 프로젝트로 진행되었습니다.

---

## 📞 문의

프로젝트에 대한 문의사항은 이슈를 등록해주세요.

---

**Made with ❤️ by SSAFY A301 Team**
