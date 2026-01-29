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

        # ROS2 파라미터 선언
        self.declare_parameter('speaker_device_name', 'UACDemo')

        self.sub_res = self.create_subscription(String, 'llm_response', self.tts_callback, 10)
        self.sub_chat = self.create_subscription(Bool, 'is_chatting', self.chat_state_callback, 10)
        self.done_pub = self.create_publisher(Bool, 'tts_done', 10)

        speaker_name = self.get_parameter('speaker_device_name').value
        self.speaker_device_id = self.find_device_by_name(speaker_name)
        self.get_logger().info(f"선택된 스피커 장치 ID: {self.speaker_device_id} ({speaker_name})")

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
        
        # 상태 관리 초기값 False
        self.is_session_active = False
        
        self.get_logger().info("★★★ TTS 노드 가동 ★★★")

    def find_device_by_name(self, name_keyword):
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if name_keyword.lower() in dev['name'].lower():
                return i
        return None

    def chat_state_callback(self, msg):
        # [수정] 로직 순서 및 조건 강화
        if msg.data is True:
            # 대화가 시작됨을 저장
            self.is_session_active = True
            self.get_logger().info("대화 세션 활성화")
        
        elif msg.data is False:
            # 세션이 활성화 상태였을 때만 "종료" 음성 출력
            if self.is_session_active:
                self.get_logger().info("대화 세션 종료 신호 수신. 종료 인사 출력.")
                self.play_tts("대화를 종료합니다.")
                self.is_session_active = False
            else:
                self.get_logger().info("이미 종료된 세션이거나 초기 상태입니다. 무시합니다.")

    def tts_callback(self, msg):
        self.play_tts(msg.data)
        time.sleep(0.3) 
        self.done_pub.publish(Bool(data=True))

    def play_tts(self, text):
        try:
            audio = self.tts.generate(text, sid=0)
            samples = audio.samples
            duration = len(samples) / audio.sample_rate
            resampled = np.interp(np.linspace(0, duration, int(duration * self.target_sample_rate)),
                                 np.linspace(0, duration, len(samples)), samples)
            
            sd.play((resampled * 32767).astype(np.int16), self.target_sample_rate, device=self.speaker_device_id)
            sd.wait() 
        except Exception as e:
            self.get_logger().error(f"TTS 재생 실패: {e}")

def main(args=None):
    rclpy.init(args=args)
    node = NoilTTSNode()
    rclpy.spin(node)
    node.destroy_node(); rclpy.shutdown()