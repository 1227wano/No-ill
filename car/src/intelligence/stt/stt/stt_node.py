#!/usr/bin/env python3
"""
음성 인식 (STT) 노드

기능:
- Sherpa-ONNX 기반 실시간 한국어 음성 인식
- 핫워드 감지로 대화 시작
- 일반 모드 / 응급 모드 분리
- TTS 재생 중 마이크 뮤트

토픽:
- 발행: /is_chatting (Bool) - 대화 상태
       /stt_result (String) - 일반 인식 결과
       /emergency_stt_result (String) - 응급 인식 결과
- 구독: /tts_done (Bool) - TTS 완료
       /force_listen (Bool) - 강제 청취 모드
       /stt_mute (Bool) - 마이크 뮤트
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
import sherpa_onnx
import sounddevice as sd
import os
from pathlib import Path
from typing import List, Optional
from ament_index_python.packages import get_package_share_directory
from sherpa_onnx.lib._sherpa_onnx import (
    OnlineRecognizerConfig,
    OnlineModelConfig,
    OnlineTransducerModelConfig,
    FeatureExtractorConfig,
    OnlineRecognizer,
    EndpointConfig,
    EndpointRule
)


class NoilSTTNode(Node):
    """음성 인식 노드
    
    Sherpa-ONNX를 사용한 실시간 한국어 음성 인식
    핫워드 기반 대화 시작 및 응급 모드 지원
    """

    # 오디오 설정
    SAMPLE_RATE = 16000
    CHANNELS = 1
    BLOCKSIZE = 1600

    # 타임아웃 설정
    CONVERSATION_TIMEOUT = 7.0  # 대화 타임아웃 (초)

    # 로그 설정
    HOTWORD_LOG_INTERVAL = 10   # 핫워드 대기 중 로그 간격

    # 모델 설정
    MODEL_DIR = "/home/jetson/sherpa-onnx/sherpa-onnx-streaming-zipformer-korean-2024-06-16"

    # 엔드포인트 설정
    ENDPOINT_RULES = {
        'rule1': {'must_contain_nonsilence': True, 'min_trailing_silence': 3.0, 'min_utterance_length': 0.0},
        'rule2': {'must_contain_nonsilence': True, 'min_trailing_silence': 2.0, 'min_utterance_length': 0.5},
        'rule3': {'must_contain_nonsilence': False, 'min_trailing_silence': 0.0, 'min_utterance_length': 20.0}
    }

    def __init__(self):
        super().__init__('stt_node')

        # 상태 변수
        self.is_chatting = False
        self.can_listen = False
        self.is_emergency_mode = False
        self.is_muted = False
        self.hotword_log_counter = 0

        # 타이머
        self.timeout_timer: Optional[rclpy.timer.Timer] = None

        # ROS2 인터페이스
        self._init_publishers()
        self._init_subscribers()

        # 마이크 설정
        self.mic_device_id = self._find_microphone()

        # 핫워드 로드
        self.hotwords_filepath = self._get_hotwords_path()
        self.keywords = self._load_hotwords()

        # Sherpa-ONNX 초기화
        self._init_recognizer()

        # 마이크 스트림 시작
        self._start_microphone()

        self._log_configuration()

    # =====================================================
    # 초기화
    # =====================================================

    def _init_publishers(self):
        """발행자 초기화"""
        self.pub_is_chatting = self.create_publisher(Bool, 'is_chatting', 10)
        self.pub_stt_result = self.create_publisher(String, 'stt_result', 10)
        self.pub_emergency_stt_result = self.create_publisher(
            String, 'emergency_stt_result', 10
        )

    def _init_subscribers(self):
        """구독자 초기화"""
        self.sub_tts_done = self.create_subscription(
            Bool, 'tts_done', self._tts_done_callback, 10
        )
        self.sub_force_listen = self.create_subscription(
            Bool, 'force_listen', self._force_listen_callback, 10
        )
        self.sub_stt_mute = self.create_subscription(
            Bool, 'stt_mute', self._stt_mute_callback, 10
        )

    def _find_microphone(self) -> Optional[int]:
        """Brio 마이크 찾기

        sounddevice에서 이름으로 찾고, 못 찾으면
        ALSA hw:1,0 (Brio USB Audio)을 직접 사용

        Returns:
            Optional[int]: 마이크 장치 ID
        """
        devices = sd.query_devices()

        # 1차: 이름으로 검색 (입력 채널이 있는 장치만)
        for i, dev in enumerate(devices):
            if 'brio' in dev['name'].lower() and dev['max_input_channels'] > 0:
                self.get_logger().info(f'[STT] Mic found: {dev["name"]} (ID: {i})')
                return i

        # 2차: ALSA hw:1,0 직접 시도 (Brio USB Audio 고정 위치)
        try:
            test_stream = sd.InputStream(device='hw:1,0', channels=1, samplerate=16000)
            test_stream.close()
            self.get_logger().info('[STT] Mic found via ALSA: hw:1,0')
            return 'hw:1,0'
        except Exception:
            pass

        self.get_logger().warn('[STT] Brio mic not found, using default')
        return None

    def _get_hotwords_path(self) -> str:
        """핫워드 파일 경로 가져오기
        
        Returns:
            str: 핫워드 파일 경로
        """
        package_share_dir = get_package_share_directory('stt')
        return os.path.join(package_share_dir, 'hotwords.txt')

    def _load_hotwords(self) -> List[str]:
        """핫워드 파일 로드
        
        Returns:
            List[str]: 핫워드 리스트
        """
        if not os.path.exists(self.hotwords_filepath):
            self.get_logger().warn(f'⚠️  Hotwords file not found: {self.hotwords_filepath}')
            return []

        keywords = []
        with open(self.hotwords_filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    # "키워드:가중치" 형식에서 키워드만 추출
                    keyword = line.split(':')[0].strip()
                    keywords.append(keyword)

        self.get_logger().info(f'✅ Loaded {len(keywords)} hotwords')
        return keywords

    def _init_recognizer(self):
        """Sherpa-ONNX 인식기 초기화"""
        # Feature Extractor 설정
        feat_config = FeatureExtractorConfig(
            sampling_rate=self.SAMPLE_RATE,
            feature_dim=80
        )

        # 모델 설정
        model_config = OnlineModelConfig(
            transducer=OnlineTransducerModelConfig(
                encoder=f"{self.MODEL_DIR}/encoder-epoch-99-avg-1.onnx",
                decoder=f"{self.MODEL_DIR}/decoder-epoch-99-avg-1.onnx",
                joiner=f"{self.MODEL_DIR}/joiner-epoch-99-avg-1.onnx"
            ),
            tokens=f"{self.MODEL_DIR}/tokens.txt",
            num_threads=2,
            model_type="zipformer"
        )

        # 엔드포인트 설정
        endpoint_config = EndpointConfig(
            rule1=EndpointRule(**self.ENDPOINT_RULES['rule1']),
            rule2=EndpointRule(**self.ENDPOINT_RULES['rule2']),
            rule3=EndpointRule(**self.ENDPOINT_RULES['rule3'])
        )

        # 인식기 설정
        recognizer_config = OnlineRecognizerConfig(
            feat_config=feat_config,
            model_config=model_config,
            endpoint_config=endpoint_config,
            enable_endpoint=True,
            decoding_method="greedy_search",
            max_active_paths=4,
            hotwords_file=self.hotwords_filepath,
            hotwords_score=2.0
        )

        # 인식기 생성
        self.recognizer = OnlineRecognizer(recognizer_config)
        self.stream = self.recognizer.create_stream()

        self.get_logger().info('✅ Sherpa-ONNX recognizer initialized')

    def _start_microphone(self):
        """마이크 스트림 시작"""
        try:
            self.mic_stream = sd.InputStream(
                device=self.mic_device_id,
                channels=self.CHANNELS,
                samplerate=self.SAMPLE_RATE,
                callback=self._audio_callback,
                dtype='float32',
                blocksize=self.BLOCKSIZE
            )
            self.mic_stream.start()
            self.get_logger().info('✅ Microphone stream started')
        except Exception as e:
            self.get_logger().error(f'❌ Failed to start microphone: {e}')
            raise

    def _log_configuration(self):
        """설정 로그"""
        self.get_logger().info(
            f'[STT] Started | mic={self.mic_device_id} | '
            f'hotwords={len(self.keywords)} | timeout={self.CONVERSATION_TIMEOUT}s'
        )

    # =====================================================
    # 콜백
    # =====================================================

    def _stt_mute_callback(self, msg: Bool):
        """STT 뮤트 콜백 (TTS 재생 중)
        
        TTS 재생 중 마이크 입력 차단
        """
        self.is_muted = msg.data

        if msg.data:
            self.get_logger().debug('🔇 STT muted (TTS playing)')
        else:
            self.get_logger().debug('🔊 STT unmuted (TTS done)')

    def _force_listen_callback(self, msg: Bool):
        """강제 청취 모드 콜백 (응급 상황)
        
        응급 상황 시 핫워드 없이 즉시 청취 시작
        """
        if msg.data:
            self.get_logger().info('[STT] Force listen ON')

            self.is_muted = False
            self.recognizer.reset(self.stream)
            self.is_chatting = True
            self.can_listen = True
            self.is_emergency_mode = True

            self._reset_timeout_timer()
        else:
            self.get_logger().info('[STT] Force listen OFF')

            self.recognizer.reset(self.stream)
            self.is_chatting = False
            self.can_listen = False
            self.is_emergency_mode = False

            if self.timeout_timer:
                self.timeout_timer.cancel()
                self.timeout_timer = None

    def _tts_done_callback(self, msg: Bool):
        """TTS 완료 콜백
        
        TTS 출력 완료 시 사용자 입력 대기 시작
        """
        if msg.data and self.is_chatting:
            self.get_logger().info('[STT] Listening...')

            self.recognizer.reset(self.stream)
            self.can_listen = True

            self._reset_timeout_timer()
        else:
            self.can_listen = False

    # =====================================================
    # 오디오 처리
    # =====================================================

    def _audio_callback(self, indata, frames, time, status):
        """오디오 스트림 콜백
        
        실시간 오디오 데이터 처리 및 음성 인식
        """
        # TTS 재생 중이면 무시
        if self.is_muted:
            return

        # 핫워드 대기 중이거나 청취 가능한 상태
        if not self.is_chatting or self.can_listen:
            # 오디오 데이터 전달
            self.stream.accept_waveform(self.SAMPLE_RATE, indata.flatten())

            # 디코딩
            while self.recognizer.is_ready(self.stream):
                self.recognizer.decode_stream(self.stream)

            # 결과 확인
            result = self.recognizer.get_result(self.stream)

            if result and result.text:
                self._handle_recognition_result(result.text.strip())

    def _handle_recognition_result(self, text: str):
        """인식 결과 처리
        
        Args:
            text: 인식된 텍스트
        """
        if not text:
            return

        # 핫워드 대기 모드
        if not self.is_chatting:
            self._handle_hotword_detection(text)

        # 청취 모드 (사용자 입력 대기)
        elif self.can_listen:
            self._handle_user_input(text)

    def _handle_hotword_detection(self, text: str):
        """핫워드 감지 처리
        
        Args:
            text: 인식된 텍스트
        """
        # 로그 출력 (10번 중 1번)
        self.hotword_log_counter += 1
        if self.hotword_log_counter % self.HOTWORD_LOG_INTERVAL == 0:
            self.get_logger().debug(f'[Hotword waiting] Recognized: {text}')

        # 핫워드 확인 (공백 제거)
        clean_text = text.replace(" ", "")

        if any(keyword in clean_text for keyword in self.keywords):
            self.get_logger().info(f'[STT] Hotword: "{text}"')

            # 대화 모드 시작
            self.is_chatting = True
            self.pub_is_chatting.publish(Bool(data=True))
            self.recognizer.reset(self.stream)

    def _handle_user_input(self, text: str):
        """사용자 입력 처리
        
        Args:
            text: 인식된 텍스트
        """
        if not self.recognizer.is_endpoint(self.stream):
            return

        # 빈 입력: 타임아웃 처리
        if text == "":
            self._handle_timeout()
            return

        # 타임아웃 타이머 취소
        if self.timeout_timer:
            self.timeout_timer.cancel()
            self.timeout_timer = None

        self.get_logger().info(f'[STT] Input: "{text}"')

        # 응급 모드 / 일반 모드 분기
        if self.is_emergency_mode:
            self.pub_emergency_stt_result.publish(String(data=text))
        else:
            self.pub_stt_result.publish(String(data=text))

        # 청취 종료
        self.can_listen = False
        self.recognizer.reset(self.stream)

    # =====================================================
    # 타임아웃 관리
    # =====================================================

    def _reset_timeout_timer(self):
        """타임아웃 타이머 리셋"""
        if self.timeout_timer:
            self.timeout_timer.cancel()

        self.timeout_timer = self.create_timer(
            self.CONVERSATION_TIMEOUT,
            self._handle_timeout
        )

    def _handle_timeout(self):
        """대화 타임아웃 처리"""
        # 타이머 취소 (one-shot)
        if self.timeout_timer:
            self.timeout_timer.cancel()
            self.timeout_timer = None

        if self.is_chatting:
            self.get_logger().info('[STT] Timeout, session ended')

            # 상태 리셋
            self.is_chatting = False
            self.can_listen = False
            self.is_emergency_mode = False

            # 버퍼 클리어
            self.recognizer.reset(self.stream)

            # 대화 종료 발행
            self.pub_is_chatting.publish(Bool(data=False))

    # =====================================================
    # 정리
    # =====================================================

    def __del__(self):
        """소멸자: 마이크 스트림 정리"""
        if hasattr(self, 'mic_stream'):
            try:
                self.mic_stream.stop()
                self.mic_stream.close()
            except:
                pass


def main(args=None):
    rclpy.init(args=args)
    node = NoilSTTNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
