import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool, String
import time

class EmergencyResponseNode(Node):
    def __init__(self):
        super().__init__('emergency_response_node')
        
        # Subscribers
        self.sub_arrived = self.create_subscription(
            Bool, 'fall_arrived', self.arrived_callback, 10)
        self.sub_stt = self.create_subscription(
            String, 'stt_result', self.stt_callback, 10)
        
        # Publishers
        self.pub_tts_trigger = self.create_publisher(String, 'tts_trigger', 10)
        self.pub_capture = self.create_publisher(Bool, 'capture_command', 10)
        self.pub_check_accident = self.create_publisher(Bool, 'check_accident', 10)
        
        # 상태 변수
        self.is_emergency_active = False
        self.attempt_count = 0
        self.max_attempts = 5
        self.waiting_for_response = False
        
        self.get_logger().info('★★★ Emergency Response Node Started ★★★')
    
    def arrived_callback(self, msg):
        """차량 도착 시 긴급 프로세스 시작"""
        if msg.data is True and not self.is_emergency_active:
            self.get_logger().warn('=== EMERGENCY PROCESS STARTED ===')
            self.is_emergency_active = True
            self.attempt_count = 0
            self.ask_patient()
    
    def ask_patient(self):
        """환자에게 질문"""
        if self.attempt_count >= self.max_attempts:
            self.get_logger().warn('No response after 5 attempts. Reporting...')
            self.report_accident()
            return
        
        self.attempt_count += 1
        self.get_logger().info(f'Asking patient... (Attempt {self.attempt_count}/{self.max_attempts})')
        
        # TTS 트리거
        tts_msg = String()
        tts_msg.data = "괜찮습니까?"
        self.pub_tts_trigger.publish(tts_msg)
        
        self.waiting_for_response = True
        
        # 5초 후 응답 확인
        self.create_timer(5.0, self.check_response, callback_group=None)
    
    def check_response(self):
        """5초 후 응답 확인"""
        if self.waiting_for_response:
            self.get_logger().info('No response detected. Retrying...')
            self.waiting_for_response = False
            self.ask_patient()
    
    def stt_callback(self, msg):
        """환자 응답 감지"""
        if self.is_emergency_active and self.waiting_for_response:
            self.get_logger().info(f'Patient responded: {msg.data}')
            self.waiting_for_response = False
            self.end_emergency()
    
    def report_accident(self):
        """사고 신고 프로세스"""
        self.get_logger().warn('!!! REPORTING ACCIDENT !!!')
        
        # 1. 캡처 명령
        capture_msg = Bool()
        capture_msg.data = True
        self.pub_capture.publish(capture_msg)
        
        self.get_logger().info('Capture command sent.')
        
        # 2. 긴급 프로세스 종료
        time.sleep(0.5)  # 캡처 대기
        self.end_emergency()
    
    def end_emergency(self):
        """긴급 프로세스 종료 및 COOLDOWN"""
        self.get_logger().info('Emergency process ended. Entering COOLDOWN...')
        self.is_emergency_active = False
        self.waiting_for_response = False
        self.attempt_count = 0
        
        # check_accident False로 변경
        accident_msg = Bool()
        accident_msg.data = False
        self.pub_check_accident.publish(accident_msg)
        
        # COOLDOWN (10초)
        self.create_timer(10.0, self.cooldown_done, callback_group=None)
    
    def cooldown_done(self):
        """COOLDOWN 종료"""
        self.get_logger().info('COOLDOWN finished. Ready for next event.')

def main(args=None):
    rclpy.init(args=args)
    node = EmergencyResponseNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
