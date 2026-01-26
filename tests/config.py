"""
통합 부하 테스트 설정 파일
사용자 모델 경로 및 설정을 여기서 수정하세요.
"""

# =============================================================================
# GPU 설정
# =============================================================================
GPU_MEMORY_FRACTION = 0.375  # 16GB * 0.375 = 6GB (Jetson Orin Nano 유사)


# =============================================================================
# 객체 인식 설정
# =============================================================================
OBJECT_DETECTION = {
    # 모델 종류: "yolo", "custom_torch", "custom_tflite"
    "type": "yolo",

    # YOLO 모델 (type="yolo"일 때)
    # 예: "yolov8n.pt", "yolov8s.pt", "/workspace/models/my_yolo.pt"
    "yolo_model": "yolov8n.pt",

    # 커스텀 PyTorch 모델 (type="custom_torch"일 때)
    "custom_model_path": "/workspace/models/detection_model.pt",
    "custom_model_class": None,  # 모델 클래스 (None이면 torch.load 사용)

    # 커스텀 TFLite 모델 (type="custom_tflite"일 때)
    "tflite_model_path": "/workspace/models/detection_model.tflite",

    # 입력 크기
    "input_size": (640, 640),

    # 추론 주기 (초)
    "inference_interval": 0.1,  # 10fps
}


# =============================================================================
# STT (Speech-to-Text) 설정
# =============================================================================
STT = {
    # 모델 종류: "whisper", "custom"
    "type": "whisper",

    # Whisper 모델 크기: "tiny", "base", "small", "medium", "large"
    "whisper_model": "base",

    # 커스텀 모델 경로
    "custom_model_path": "/workspace/models/stt_model.pt",

    # 언어
    "language": "ko",

    # 처리 주기 (초)
    "process_interval": 3.0,
}


# =============================================================================
# TTS (Text-to-Speech) 설정
# =============================================================================
TTS_CONFIG = {
    # 모델 종류: "gtts", "coqui", "custom"
    "type": "gtts",

    # gTTS 설정 (type="gtts"일 때)
    "gtts_lang": "ko",  # 한국어

    # Coqui TTS 모델 (type="coqui"일 때)
    # 영어: "tts_models/en/ljspeech/tacotron2-DDC"
    "coqui_model": "tts_models/en/ljspeech/tacotron2-DDC",

    # 커스텀 모델 경로
    "custom_model_path": "/workspace/models/tts_model.pt",

    # 합성 주기 (초)
    "synthesis_interval": 2.0,
}


# =============================================================================
# 영상 스트리밍 설정
# =============================================================================
VIDEO = {
    # 소스: None (더미), 파일 경로, 또는 카메라 인덱스 (0, 1, ...)
    "source": None,

    # 테스트 영상 파일 (source=None일 때 무시)
    # 예: "/workspace/test_video.mp4"
    "test_video": None,

    # 해상도
    "width": 1280,
    "height": 720,

    # FPS
    "target_fps": 30,
}


# =============================================================================
# 라이다 시뮬레이션 설정
# =============================================================================
LIDAR = {
    # 스캔 주기 (Hz)
    "scan_rate": 10,

    # 스캔 포인트 수
    "num_points": 360,

    # 최대 거리 (m)
    "max_range": 10.0,

    # ROS2 토픽 사용 여부 (실제 ROS2 환경에서만)
    "use_ros2": False,
    "ros2_topic": "/scan",
}


# =============================================================================
# 테스트 텍스트 (TTS용)
# =============================================================================
TEST_TEXTS = [
    "안녕하세요, 저는 노일이입니다.",
    "오늘 기분이 어떠세요?",
    "도움이 필요하시면 말씀해주세요.",
    "날씨가 좋네요.",
    "식사는 하셨나요?",
    "오늘 하루도 힘내세요.",
    "괜찮으세요?",
]
