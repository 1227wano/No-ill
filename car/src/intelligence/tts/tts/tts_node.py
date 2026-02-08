#!/usr/bin/env python3
"""
음성 합성 (TTS) 노드

기능:
- Sherpa-ONNX 기반 한국어 음성 합성
- 일반 대화 / 응급 메시지 분리
- TTS 재생 중 STT 뮤트
- 시스템 초기화 비프음

토픽:
- 구독: /llm_response (String) - 일반 대화 응답
       /tts_trigger (String) - 응급 메시지
       /is_chatting (Bool) - 대화 상태
       /fall_arrived (Bool) - 응급 모드
       /test_beep (String) - 테스트 비프 요청
- 발행: /tts_done (Bool) - 일반 TTS 완료
       /emergency_tts_done (Bool) - 응급 TTS 완료
       /stt_mute (Bool) - STT 뮤트 제어
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
import sherpa_onnx
import sounddevice as sd
import numpy as np
import os
import time
from typing import Optional
from ament_index_python.packages import get_package_share_directory


class NoilTTSNode(Node):
    """음성 합성 노드
    
    Sherpa-ONNX VITS 모델을 사용한
    한국어 음성 합성 및 스피커 출력
    """

    # 오디오 설정
    TARGET_SAMPLE_RATE = 48000  # UACDemo 스피커 샘플레이트
    PLAYBACK_SPEED = 0.9        # 재생 속도 (0.9배속)
    POST_PLAY_DELAY = 0.35      # 재생 후 여유 시간 (초)

    # 비프음 설정
    BEEP_INIT_FREQ = 440        # TTS 초기화 비프 (A4)
    BEEP_CAMERA_FREQ = 880      # 카메라 초기화 비프 (A5)
    BEEP_INIT_DURATION = 0.2    # TTS 비프 길이 (초)
    BEEP_CAMERA_DURATION = 0.15 # 카메라 비프 길이 (초)
    BEEP_VOLUME = 0.3           # 비프 볼륨 (0~1)
    BEEP_INTERVAL = 0.1         # 비프 간격 (초)

    # 메시지 설정
    MSG_SESSION_START = "네, 말씀하세요."
    MSG_SESSION_END = "대화를 종료합니다."

    def __init__(self):
        super().__init__('tts_node')

        # 상태 변수
        self.is_session_active = False
        self.is_emergency_mode = False

        # ROS2 인터페이스
        self._init_subscribers()
        self._init_publishers()

        # 스피커 설정
        self.speaker_device_id = self._find_speaker()

        # TTS 엔진 초기화
        self._init_tts_engine()

        self._log_configuration()

        # 초기화 완료 비프음 (2회)
        self._play_init_beep()

    # =====================================================
    # 초기화
    # =====================================================

    def _init_subscribers(self):
        """구독자 초기화"""
        self.sub_llm_response = self.create_subscription(
            String, 'llm_response', self._llm_response_callback, 10
        )
        self.sub_is_chatting = self.create_subscription(
            Bool, 'is_chatting', self._is_chatting_callback, 10
        )
        self.sub_tts_trigger = self.create_subscription(
            String, 'tts_trigger', self._tts_trigger_callback, 10
        )
        self.sub_fall_arrived = self.create_subscription(
            Bool, 'fall_arrived', self._fall_arrived_callback, 10
        )
        self.sub_test_beep = self.create_subscription(
            String, 'test_beep', self._test_beep_callback, 10
        )

    def _init_publishers(self):
        """발행자 초기화"""
        self.pub_tts_done = self.create_publisher(Bool, 'tts_done', 10)
        self.pub_emergency_tts_done = self.create_publisher(
            Bool, 'emergency_tts_done', 10
        )
        self.pub_stt_mute = self.create_publisher(Bool, 'stt_mute', 10)

    def _find_speaker(self) -> Optional[int]:
        """UACDemo 스피커 찾기
        
        Returns:
            Optional[int]: 스피커 장치 ID
        """
        devices = sd.query_devices()

        for i, dev in enumerate(devices):
            if 'uacdemo' in dev['name'].lower():
                self.get_logger().info(
                    f'✅ Found speaker: {dev["name"]} (ID: {i})'
                )
                return i

        self.get_logger().warn(
            '⚠️  UACDemo speaker not found. Using default.'
        )
        return None

    def _init_tts_engine(self):
        """Sherpa-ONNX TTS 엔진 초기화"""
        pkg_share = get_package_share_directory('tts')

        # VITS 모델 설정
        vits_config = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=os.path.join(pkg_share, 'models', 'tts_model.onnx'),
            tokens=os.path.join(pkg_share, 'models', 'tokens.txt'),
            data_dir=os.path.join(pkg_share, 'models'),
            length_scale=1.0
        )

        # TTS 엔진 생성
        tts_config = sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(
                vits=vits_config,
                num_threads=2
            )
        )

        self.tts = sherpa_onnx.OfflineTts(tts_config)

        self.get_logger().info('✅ TTS engine initialized')

    def _log_configuration(self):
        """설정 로그"""
        self.get_logger().info('=' * 50)
        self.get_logger().info('★★★ TTS Node Started ★★★')
        self.get_logger().info('=' * 50)
        self.get_logger().info(f'Speaker ID: {self.speaker_device_id}')
        self.get_logger().info(f'Sample rate: {self.TARGET_SAMPLE_RATE} Hz')
        self.get_logger().info(f'Playback speed: {self.PLAYBACK_SPEED}x')
        self.get_logger().info('=' * 50)

    # =====================================================
    # 콜백
    # =====================================================

    def _fall_arrived_callback(self, msg: Bool):
        """응급 모드 상태 추적
        
        fall_arrived = True 시 응급 모드 진입
        """
        self.is_emergency_mode = msg.data

        if msg.data:
            self.get_logger().info('🚨 Emergency mode ON (fall_arrived)')
        else:
            self.get_logger().info('✓ Emergency mode OFF')

    def _is_chatting_callback(self, msg: Bool):
        """대화 상태 콜백
        
        대화 시작 시 환영 메시지
        대화 종료 시 종료 메시지
        """
        if msg.data:
            # 대화 시작
            self.is_session_active = True
            self.get_logger().info('💬 Conversation session STARTED')

            # 응급 모드가 아닐 때만 환영 메시지
            if not self.is_emergency_mode:
                self._play_tts(self.MSG_SESSION_START)
                self.pub_tts_done.publish(Bool(data=True))
        else:
            # 대화 종료
            if self.is_session_active:
                self.is_session_active = False

                if self.is_emergency_mode:
                    self.get_logger().info(
                        '🚨 Emergency mode end. Skipping farewell.'
                    )
                else:
                    self.get_logger().info('💬 Conversation session ENDED')
                    self._play_tts(self.MSG_SESSION_END)
            else:
                self.get_logger().debug('Session already inactive. Ignored.')

    def _llm_response_callback(self, msg: String):
        """일반 대화 TTS 콜백
        
        LLM 응답을 음성으로 출력
        """
        self.get_logger().info(f'🗣️  LLM response: "{msg.data}"')
        self._play_tts(msg.data)
        self.pub_tts_done.publish(Bool(data=True))

    def _tts_trigger_callback(self, msg: String):
        """응급 메시지 TTS 콜백
        
        응급 상황 메시지를 음성으로 출력
        """
        self.get_logger().info(f'🚨 Emergency TTS: "{msg.data}"')
        self._play_tts(msg.data)
        self.pub_emergency_tts_done.publish(Bool(data=True))

    def _test_beep_callback(self, msg: String):
        """테스트 비프 콜백
        
        시스템 초기화 완료 신호
        """
        if msg.data == "CAMERA_OK":
            self._play_camera_beep()

    # =====================================================
    # TTS 재생
    # =====================================================

    def _play_tts(self, text: str):
        """텍스트를 음성으로 변환 및 재생
        
        Args:
            text: 합성할 텍스트
        """
        try:
            # STT 뮤트 (TTS 재생 중)
            self.pub_stt_mute.publish(Bool(data=True))

            # 음성 합성
            audio = self.tts.generate(text, sid=0)
            samples = audio.samples
            duration = len(samples) / audio.sample_rate

            # 재생 속도 조정 (0.9배속)
            adjusted_duration = duration / self.PLAYBACK_SPEED
            resampled = np.interp(
                np.linspace(0, duration, int(adjusted_duration * self.TARGET_SAMPLE_RATE)),
                np.linspace(0, duration, len(samples)),
                samples
            )

            # 재생
            sd.play(
                (resampled * 32767).astype(np.int16),
                self.TARGET_SAMPLE_RATE,
                device=self.speaker_device_id
            )
            sd.wait()

            # 재생 후 여유 시간
            time.sleep(self.POST_PLAY_DELAY)

            # STT 뮤트 해제
            self.pub_stt_mute.publish(Bool(data=False))

        except Exception as e:
            self.get_logger().error(f'❌ TTS playback failed: {e}')
            # 에러 시에도 뮤트 해제
            self.pub_stt_mute.publish(Bool(data=False))

    # =====================================================
    # 비프음
    # =====================================================

    def _play_init_beep(self):
        """TTS 초기화 완료 비프음 (2회)
        
        440Hz (A4 음) 0.2초씩 2회
        """
        try:
            beep = self._generate_beep(
                self.BEEP_INIT_FREQ,
                self.BEEP_INIT_DURATION
            )

            # 첫 번째 비프
            sd.play(beep, self.TARGET_SAMPLE_RATE, device=self.speaker_device_id)
            sd.wait()

            time.sleep(self.BEEP_INTERVAL)

            # 두 번째 비프
            sd.play(beep, self.TARGET_SAMPLE_RATE, device=self.speaker_device_id)
            sd.wait()

            self.get_logger().info('✓ TTS speaker test OK (2 beeps)')

        except Exception as e:
            self.get_logger().error(f'✗ TTS speaker test FAILED: {e}')

    def _play_camera_beep(self):
        """카메라 초기화 완료 비프음 (3회)
        
        880Hz (A5 음) 0.15초씩 3회
        """
        try:
            beep = self._generate_beep(
                self.BEEP_CAMERA_FREQ,
                self.BEEP_CAMERA_DURATION
            )

            for i in range(3):
                sd.play(beep, self.TARGET_SAMPLE_RATE, device=self.speaker_device_id)
                sd.wait()

                if i < 2:  # 마지막 비프 후엔 대기 안 함
                    time.sleep(self.BEEP_INTERVAL)

            self.get_logger().info('✓ Camera test beep OK (3 beeps)')

        except Exception as e:
            self.get_logger().error(f'✗ Camera test beep FAILED: {e}')

    def _generate_beep(self, frequency: float, duration: float) -> np.ndarray:
        """비프음 생성
        
        Args:
            frequency: 주파수 (Hz)
            duration: 길이 (초)
            
        Returns:
            np.ndarray: 비프음 샘플 (int16)
        """
        samples = int(self.TARGET_SAMPLE_RATE * duration)
        t = np.linspace(0, duration, samples)

        # 사인파 생성
        sine_wave = np.sin(2 * np.pi * frequency * t)

        # 볼륨 적용 및 int16 변환
        beep = (sine_wave * 32767 * self.BEEP_VOLUME).astype(np.int16)

        return beep


def main(args=None):
    rclpy.init(args=args)
    node = NoilTTSNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
