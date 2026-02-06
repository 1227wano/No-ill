import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
import sherpa_onnx
import sounddevice as sd
import os
import threading
from ament_index_python.packages import get_package_share_directory
from sherpa_onnx.lib._sherpa_onnx import (
    OnlineRecognizerConfig, OnlineModelConfig, OnlineTransducerModelConfig,
    FeatureExtractorConfig, OnlineRecognizer, EndpointConfig, EndpointRule
)

class NoilSTTNode(Node):
    def __init__(self):
        super().__init__('stt_node')
        
        # Publishers
        self.is_chatting_pub = self.create_publisher(Bool, 'is_chatting', 10)
        self.stt_result_pub = self.create_publisher(String, 'stt_result', 10)
        self.emergency_stt_result_pub = self.create_publisher(String, 'emergency_stt_result', 10)
        self.tts_done_pub = self.create_publisher(Bool, 'tts_done', 10)
        
        # Subscribers
        self.tts_done_sub = self.create_subscription(Bool, 'tts_done', self.tts_done_callback, 10)
        self.force_listen_sub = self.create_subscription(Bool, 'force_listen', self.force_listen_callback, 10)
        self.stt_mute_sub = self.create_subscription(Bool, 'stt_mute', self.stt_mute_callback, 10)  # TTS 재생 중 뮤트

        self.is_chatting = False
        self.can_listen = False
        self.timeout_timer = None
        self.is_emergency_mode = False
        self.is_muted = False  # TTS 재생 중 마이크 차단용
        self.log_counter = 0  # 디버깅 로그 카운터

        self.mic_device_id = self.find_device_by_name("Brio")
        self.get_logger().info(f"선택된 마이크 장치 ID: {self.mic_device_id}")

        model_dir = "/home/jetson/sherpa-onnx/sherpa-onnx-streaming-zipformer-korean-2024-06-16"
        package_share_dir = get_package_share_directory('stt')
        self.hotwords_filepath = os.path.join(package_share_dir, 'hotwords.txt')
        self.keywords = self.load_hotwords(self.hotwords_filepath)
        
        feat_config = FeatureExtractorConfig(sampling_rate=16000, feature_dim=80)
        model_config = OnlineModelConfig(
            transducer=OnlineTransducerModelConfig(
                encoder=f"{model_dir}/encoder-epoch-99-avg-1.onnx",
                decoder=f"{model_dir}/decoder-epoch-99-avg-1.onnx",
                joiner=f"{model_dir}/joiner-epoch-99-avg-1.onnx"
            ),
            tokens=f"{model_dir}/tokens.txt", num_threads=2, model_type="zipformer"
        )
        
        endpoint_config = EndpointConfig(
            rule1=EndpointRule(must_contain_nonsilence=True, min_trailing_silence=3.0, min_utterance_length=0.0),
            rule2=EndpointRule(must_contain_nonsilence=True, min_trailing_silence=2.0, min_utterance_length=0.5),
            rule3=EndpointRule(must_contain_nonsilence=False, min_trailing_silence=0.0, min_utterance_length=20.0)
        )
        
        recon_config = OnlineRecognizerConfig(
            feat_config=feat_config, model_config=model_config,
            endpoint_config=endpoint_config, enable_endpoint=True,
            decoding_method="greedy_search", max_active_paths=4,
            hotwords_file=self.hotwords_filepath, hotwords_score=2.0
        )
        self.recognizer = OnlineRecognizer(recon_config)
        self.stream = self.recognizer.create_stream()

        try:
            self.mic_stream = sd.InputStream(device=self.mic_device_id, channels=1, samplerate=16000,
                                            callback=self.audio_callback, dtype="float32", blocksize=1600)
            self.mic_stream.start()
            self.get_logger().info("★★★ STT 제어 노드 가동 ★★★")
        except Exception as e:
            self.get_logger().error(f"마이크 시작 실패: {e}")

    def find_device_by_name(self, name_keyword):
        devices = sd.query_devices()
        for i, dev in enumerate(devices):
            if name_keyword.lower() in dev['name'].lower():
                return i
        return None

    def load_hotwords(self, filepath):
        if not os.path.exists(filepath): return []
        with open(filepath, 'r', encoding='utf-8') as f:
            return [line.strip().split(':')[0].strip() for line in f if line.strip()]

    def stt_mute_callback(self, msg):
        """TTS 재생 중 마이크 뮤트 제어"""
        self.is_muted = msg.data
        if msg.data:
            self.get_logger().info("STT muted (TTS playing)")
        else:
            self.get_logger().info("STT unmuted (TTS done)")

    def force_listen_callback(self, msg):
        """긴급 상황 강제 청취 모드"""
        if msg.data is True:
            self.get_logger().info("Force listen mode activated.")
            self.is_muted = False
            self.recognizer.reset(self.stream)
            self.is_chatting = True
            self.can_listen = True
            self.is_emergency_mode = True
            self.reset_timeout_timer()
        else:
            self.get_logger().info("Force listen mode deactivated.")
            # is_muted를 True로 설정하지 않음 - 핫워드 대기로 복귀해야 함
            self.recognizer.reset(self.stream)  # 버퍼 클리어
            self.is_chatting = False
            self.can_listen = False
            self.is_emergency_mode = False
            if self.timeout_timer:
                self.timeout_timer.cancel()

    def tts_done_callback(self, msg):
        if msg.data and self.is_chatting:
            self.get_logger().info("TTS 종료. 입력 대기 시작.")
            self.recognizer.reset(self.stream)
            self.can_listen = True
            self.reset_timeout_timer()
        else:
            self.can_listen = False

    def reset_timeout_timer(self):
        if self.timeout_timer: self.timeout_timer.cancel()
        self.timeout_timer = threading.Timer(7.0, self.handle_timeout)
        self.timeout_timer.start()

    def handle_timeout(self):
        if self.is_chatting:
            self.get_logger().info("--- 타임아웃: 대화 종료 ---")
            self.is_chatting = False
            self.can_listen = False
            self.is_emergency_mode = False  # 응급 모드도 해제
            if self.timeout_timer:
                self.timeout_timer.cancel()
            self.recognizer.reset(self.stream)  # 버퍼 즉시 클리어
            self.is_chatting_pub.publish(Bool(data=False))

    def audio_callback(self, indata, frames, time, status):
        if self.is_muted:
            return

        if not self.is_chatting or self.can_listen:
            self.stream.accept_waveform(16000, indata.flatten())
            while self.recognizer.is_ready(self.stream):
                self.recognizer.decode_stream(self.stream)
            
            result = self.recognizer.get_result(self.stream)
            if result and result.text:
                raw_text = result.text.strip()
                
                if not self.is_chatting:
                    # 핫워드 대기 중 - 10번 중 1번만 로그 출력
                    self.log_counter += 1
                    if self.log_counter % 10 == 0:
                        self.get_logger().info(f"[핫워드 대기] 인식: {raw_text}")
                    
                    clean_text = raw_text.replace(" ", "")
                    if any(k in clean_text for k in self.keywords):
                        self.get_logger().info(f"▶ 핫워드 감지: {raw_text}")
                        self.is_chatting = True
                        self.is_chatting_pub.publish(Bool(data=True))
                        self.recognizer.reset(self.stream)
                
                elif self.can_listen:
                    if self.recognizer.is_endpoint(self.stream):
                        if raw_text == "":
                            self.handle_timeout()
                        else:
                            if self.timeout_timer: self.timeout_timer.cancel()
                            self.get_logger().info(f"사용자 입력: {raw_text}")
                            if self.is_emergency_mode:
                                self.emergency_stt_result_pub.publish(String(data=raw_text))
                            else:
                                self.stt_result_pub.publish(String(data=raw_text))
                            self.can_listen = False
                        self.recognizer.reset(self.stream)

def main(args=None):
    rclpy.init(args=args)
    node = NoilSTTNode()
    try: rclpy.spin(node)
    except KeyboardInterrupt: pass
    finally: node.destroy_node(); rclpy.shutdown()

if __name__ == '__main__':
    main()