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
            String, 'emergency_stt_result', self.stt_callback, 10)
        self.sub_emergency_tts_done = self.create_subscription(
            Bool, 'emergency_tts_done', self.emergency_tts_done_callback, 10)
        
        # Publishers
        self.pub_tts_trigger = self.create_publisher(String, 'tts_trigger', 10)
        self.pub_capture = self.create_publisher(Bool, 'capture_command', 10)
        self.pub_check_accident = self.create_publisher(Bool, 'check_accident', 10)
        self.pub_force_listen = self.create_publisher(Bool, 'force_listen', 10)
        self.pub_is_chatting = self.create_publisher(Bool, 'is_chatting', 10)
        self.pub_fall_arrived = self.create_publisher(Bool, 'fall_arrived', 10)
        
        # 상태 변수
        self.is_emergency_active = False
        self.attempt_count = 0
        self.max_attempts = 5
        self.waiting_for_response = False

        # 타이머 (취소 가능하도록 저장)
        self.response_timer = None
        self.cooldown_timer = None
        
        self.get_logger().info('★★★ Emergency Response Node Started ★★★')
    
    def arrived_callback(self, msg):
        """차량 도착 시 긴급 프로세스 시작"""
        if msg.data is True and not self.is_emergency_active:
            self.get_logger().warn('=== EMERGENCY PROCESS STARTED ===')
            self.is_emergency_active = True
            self.attempt_count = 0

            # tts_node가 fall_arrived를 먼저 처리하도록 대기
            time.sleep(0.1)

            # 주행 정지 (chat_stop_gate 활성화)
            chatting_msg = Bool()
            chatting_msg.data = True
            self.pub_is_chatting.publish(chatting_msg)

            self.ask_patient()
    
    def ask_patient(self):
        """환자에게 질문"""
        if self.attempt_count >= self.max_attempts:
            self.get_logger().warn('No response after 5 attempts. Reporting...')
            self.report_accident()
            return

        self.attempt_count += 1
        self.get_logger().info(f'Asking patient... (Attempt {self.attempt_count}/{self.max_attempts})')

        # TTS 출력 중 STT 입력 차단
        listen_msg = Bool()
        listen_msg.data = False
        self.pub_force_listen.publish(listen_msg)

        # TTS 트리거 (완료 후 emergency_tts_done_callback에서 청취 활성화)
        tts_msg = String()
        tts_msg.data = "괜찮습니까?"
        self.pub_tts_trigger.publish(tts_msg)

    def emergency_tts_done_callback(self, msg):
        """Emergency TTS 완료 후 청취 활성화"""
        if msg.data and self.is_emergency_active:
            self.get_logger().info('Emergency TTS done. Activating listen mode.')

            # STT 강제 청취 모드 활성화 (테스트용 비활성화)
            ##########################################################
            listen_msg = Bool()
            listen_msg.data = True
            self.pub_force_listen.publish(listen_msg)
            ##########################################################

            self.waiting_for_response = True

            # 5초 후 응답 확인 (기존 타이머 취소 후 새로 생성)
            if self.response_timer:
                self.response_timer.cancel()
            self.response_timer = self.create_timer(5.0, self.check_response)
    
    def check_response(self):
        """3초 후 응답 확인"""
        # 타이머 1회 실행 후 취소
        if self.response_timer:
            self.response_timer.cancel()
            self.response_timer = None

        if self.waiting_for_response:
            self.get_logger().info('No response detected. Retrying...')
            self.waiting_for_response = False
            self.ask_patient()
    
    def stt_callback(self, msg):
        """환자 응답 감지"""
        if self.is_emergency_active and self.waiting_for_response:
            user_text = msg.data
            self.get_logger().info(f'Patient responded: {user_text}')

            # 긍정 응답 키워드 확인
            positive_keywords = ["응", "어", "괜찮", "됐"]
            if any(keyword in user_text for keyword in positive_keywords):  # ← 포함 여부 체크
                # 응답 타이머 취소
                if self.response_timer:
                    self.response_timer.cancel()
                    self.response_timer = None

                self.waiting_for_response = False

                # 응답 확인 메시지 출력
                tts_msg = String()
                tts_msg.data = "네, 괜찮으시군요!"
                self.pub_tts_trigger.publish(tts_msg)

                self.end_emergency()
            else:
                # 키워드 없으면 무시하고 계속 대기
                self.get_logger().info(f'No positive keyword detected. Waiting...')
    
    def report_accident(self):
        """사고 신고 프로세스"""
        self.get_logger().warn('!!! REPORTING ACCIDENT !!!')

        # 1. 캡처 명령
        capture_msg = Bool()
        capture_msg.data = True
        self.pub_capture.publish(capture_msg)

        self.get_logger().info('Capture command sent.')

        # 2. 신고 완료 TTS 출력 (일회성)
        tts_msg = String()
        tts_msg.data = "신고를 완료했습니다."
        self.pub_tts_trigger.publish(tts_msg)

        # 3. 긴급 프로세스 종료
        time.sleep(0.5)  # 캡처 대기
        self.end_emergency()
    
    def end_emergency(self):
        """긴급 프로세스 종료 및 COOLDOWN"""
        self.get_logger().info('Emergency process ended. Entering COOLDOWN...')

        # 남아있는 타이머 취소
        if self.response_timer:
            self.response_timer.cancel()
            self.response_timer = None

        self.is_emergency_active = False
        self.waiting_for_response = False
        self.attempt_count = 0

        # STT 강제 청취 모드 해제
        listen_msg = Bool()
        listen_msg.data = False
        self.pub_force_listen.publish(listen_msg)

        # 주행 재개 (chat_stop_gate 비활성화)
        chatting_msg = Bool()
        chatting_msg.data = False
        self.pub_is_chatting.publish(chatting_msg)

        # check_accident False로 변경
        accident_msg = Bool()
        accident_msg.data = False
        self.pub_check_accident.publish(accident_msg)

        # tts_node의 is_emergency_mode 리셋
        fall_msg = Bool()
        fall_msg.data = False
        self.pub_fall_arrived.publish(fall_msg)

        # COOLDOWN (1시간)
        if self.cooldown_timer:
            self.cooldown_timer.cancel()
        self.cooldown_timer = self.create_timer(3600.0, self.cooldown_done)
    
    def cooldown_done(self):
        """COOLDOWN 종료"""
        # 타이머 1회 실행 후 취소
        if self.cooldown_timer:
            self.cooldown_timer.cancel()
            self.cooldown_timer = None
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