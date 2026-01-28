import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import sherpa_onnx
import sounddevice as sd
import numpy as np
import os
from ament_index_python.packages import get_package_share_directory

class NoilTTSNode(Node):
    def __init__(self):
        super().__init__('tts_node')
        self.subscription = self.create_subscription(String, 'llm_response', self.tts_callback, 10)

        # 1. 장치 자동 찾기 (UACDemo)
        self.target_device = self.find_device_by_name("UACDemo")
        if self.target_device is None:
            self.get_logger().error("스피커를 찾을 수 없어 25번을 사용합니다.")
            self.target_device = 25
        
        self.target_sample_rate = 48000
        sd.default.device = self.target_device

        # 2. TTS 엔진 설정
        pkg_share = get_package_share_directory('tts')
        vits_config = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=os.path.join(pkg_share, 'models', 'tts_model.onnx'),
            tokens=os.path.join(pkg_share, 'models', 'tokens.txt'),
            data_dir=os.path.join(pkg_share, 'models'),
            length_scale=1.0
        )
        self.tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(vits=vits_config, num_threads=2)
        ))
        self.get_logger().info(f"★★★ TTS 가동 (ID: {self.target_device}) ★★★")

    def find_device_by_name(self, name_keyword):
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if name_keyword in dev['name']: return i
        return None

    def tts_callback(self, msg):
        if not msg.data.strip(): return
        try:
            audio = self.tts.generate(msg.data, sid=0)
            samples = audio.samples
            if audio.sample_rate != self.target_sample_rate:
                duration = len(samples) / audio.sample_rate
                samples = np.interp(np.linspace(0, duration, int(duration * self.target_sample_rate)),
                                    np.linspace(0, duration, len(samples)), samples)
            
            sd.play((samples * 32767).astype(np.int16), self.target_sample_rate)
            sd.wait()
        except Exception as e: self.get_logger().error(f"TTS 오류: {e}")

def main(args=None):
    rclpy.init(args=args)
    node = NoilTTSNode()
    try: rclpy.spin(node)
    except KeyboardInterrupt: pass
    finally: node.destroy_node(); rclpy.shutdown()

if __name__ == '__main__': main()