import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
import sherpa_onnx
import sounddevice as sd
import numpy as np
import os
import time
from ament_index_python.packages import get_package_share_directory

class NoilTTSNode(Node):
    def __init__(self):
        super().__init__('tts_node')

        # Subscribers
        self.sub_res = self.create_subscription(String, 'llm_response', self.tts_callback, 10)
        self.sub_chat = self.create_subscription(Bool, 'is_chatting', self.chat_state_callback, 10)
        self.sub_trigger = self.create_subscription(String, 'tts_trigger', self.emergency_tts_callback, 10)
        self.sub_fall_arrived = self.create_subscription(Bool, 'fall_arrived', self.fall_arrived_callback, 10)
        self.sub_test_beep = self.create_subscription(String, 'test_beep', self.test_beep_callback, 10)

        # 긴급 모드 상태
        self.is_emergency_mode = False

        # Publishers
        self.done_pub = self.create_publisher(Bool, 'tts_done', 10)
        self.emergency_done_pub = self.create_publisher(Bool, 'emergency_tts_done', 10)
        self.stt_mute_pub = self.create_publisher(Bool, 'stt_mute', 10)

        self.speaker_device_id = self.find_device_by_name("UACDemo")
        self.get_logger().info(f"선택된 스피커 장치 ID: {self.speaker_device_id}")

        pkg_share = get_package_share_directory('tts')
        vits_config = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=os.path.join(pkg_share, 'models', 'tts_model.onnx'),
            tokens=os.path.join(pkg_share, 'models', 'tokens.txt'),
            data_dir=os.path.join(pkg_share, 'models'), length_scale=1.0
        )
        self.tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(vits=vits_config, num_threads=2)
        ))
        self.target_sample_rate = 48000
        self.playback_speed = 0.9  # 0.9배속

        self.is_session_active = False

        self.get_logger().info("★★★ TTS 노드 가동 ★★★")
        
        # 초기화 완료 비프음 2회
        self.play_beep()

    def find_device_by_name(self, name_keyword):
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if name_keyword.lower() in dev['name'].lower():
                return i
        return None

    def play_beep(self):
        """TTS 초기화 완료 비프음 2회 (440Hz)"""
        try:
            # 440Hz (A4 음) 0.2초
            duration = 0.2
            frequency = 440
            samples = int(self.target_sample_rate * duration)
            t = np.linspace(0, duration, samples)
            beep = np.sin(2 * np.pi * frequency * t)
            
            # 첫 번째 비프
            sd.play((beep * 32767 * 0.3).astype(np.int16), self.target_sample_rate, device=self.speaker_device_id)
            sd.wait()
            
            time.sleep(0.1)
            
            # 두 번째 비프
            sd.play((beep * 32767 * 0.3).astype(np.int16), self.target_sample_rate, device=self.speaker_device_id)
            sd.wait()
            
            self.get_logger().info("✓ TTS Speaker test OK (2 beeps)")
        except Exception as e:
            self.get_logger().error(f"✗ TTS Speaker test FAILED: {e}")

    def test_beep_callback(self, msg):
        """카메라 테스트 비프 요청 수신"""
        if msg.data == "CAMERA_OK":
            self.play_camera_beep()

    def play_camera_beep(self):
        """카메라 초기화 완료 비프음 3회 (880Hz - 높은 라)"""
        try:
            # 880Hz (A5 음) 0.15초 (더 짧고 날카롭게)
            duration = 0.15
            frequency = 880
            samples = int(self.target_sample_rate * duration)
            t = np.linspace(0, duration, samples)
            beep = np.sin(2 * np.pi * frequency * t)
            
            for i in range(3):
                sd.play((beep * 32767 * 0.3).astype(np.int16), self.target_sample_rate, device=self.speaker_device_id)
                sd.wait()
                if i < 2:  # 마지막 비프 후엔 대기 안 함
                    time.sleep(0.1)
            
            self.get_logger().info("✓ Camera test beep OK (3 beeps)")
        except Exception as e:
            self.get_logger().error(f"✗ Camera test beep FAILED: {e}")

    def fall_arrived_callback(self, msg):
        """긴급 모드 상태 추적"""
        self.is_emergency_mode = msg.data
        if msg.data:
            self.get_logger().info("Emergency mode ON (fall_arrived)")
        else:
            self.get_logger().info("Emergency mode OFF")

    def chat_state_callback(self, msg):
        if msg.data is True:
            self.is_session_active = True
            self.get_logger().info("대화 세션 활성화")
            if not self.is_emergency_mode:
                self.play_tts("네, 말씀하세요.")
                time.sleep(0.35)  # 0.3 → 0.35 (0.9배속 고려)
                self.done_pub.publish(Bool(data=True))

        elif msg.data is False:
            if self.is_session_active:
                self.is_session_active = False
                if self.is_emergency_mode:
                    self.get_logger().info("긴급 모드 종료. 종료 인사 생략.")
                else:
                    self.get_logger().info("대화 세션 종료 신호 수신. 종료 인사 출력.")
                    self.play_tts("대화를 종료합니다.")
            else:
                self.get_logger().info("이미 종료된 세션이거나 초기 상태입니다. 무시합니다.")

    def tts_callback(self, msg):
        """일반 대화 TTS"""
        self.play_tts(msg.data)
        time.sleep(0.35)  # 0.3 → 0.35 (0.9배속 고려)
        self.done_pub.publish(Bool(data=True))

    def emergency_tts_callback(self, msg):
        """긴급 메시지 TTS"""
        self.get_logger().info(f'Emergency TTS: {msg.data}')
        self.play_tts(msg.data)
        time.sleep(0.35)  # 0.3 → 0.35 (0.9배속 고려)
        self.emergency_done_pub.publish(Bool(data=True))

    def play_tts(self, text):
        try:
            self.stt_mute_pub.publish(Bool(data=True))

            audio = self.tts.generate(text, sid=0)
            samples = audio.samples
            duration = len(samples) / audio.sample_rate
            
            # 0.9배속 적용: 재생 시간이 1/0.9 = 1.111배 길어짐
            adjusted_duration = duration / self.playback_speed
            resampled = np.interp(np.linspace(0, duration, int(adjusted_duration * self.target_sample_rate)),
                                 np.linspace(0, duration, len(samples)), samples)

            sd.play((resampled * 32767).astype(np.int16), self.target_sample_rate, device=self.speaker_device_id)
            sd.wait()

            self.stt_mute_pub.publish(Bool(data=False))
        except Exception as e:
            self.get_logger().error(f"TTS 재생 실패: {e}")
            self.stt_mute_pub.publish(Bool(data=False))

def main(args=None):
    rclpy.init(args=args)
    node = NoilTTSNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()