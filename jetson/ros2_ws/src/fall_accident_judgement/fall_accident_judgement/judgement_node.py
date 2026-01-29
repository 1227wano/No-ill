import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool

class FallJudgementNode(Node):
    def __init__(self):
        super().__init__('fall_judgement_node')

        # ROS2 파라미터 선언
        self.declare_parameter('threshold', 30)
        self.declare_parameter('event_duration', 5.0)
        self.declare_parameter('cooldown_duration', 10.0)

        # Subscriber
        self.create_subscription(String, 'object_type', self.listener_callback, 10)

        # Publisher
        self.publisher_ = self.create_publisher(Bool, 'check_accident', 10)

        # 상태 변수
        self.lying_count = 0
        self.is_paused = False
        self.timer = None  # 5초 뒤 False 전환을 위한 타이머
        self.cooldown_timer = None # 10초 휴지기를 위한 타이머

        # 설정값 (파라미터에서 로드)
        self.THRESHOLD = self.get_parameter('threshold').value
        self.EVENT_DURATION = self.get_parameter('event_duration').value
        self.COOLDOWN_DURATION = self.get_parameter('cooldown_duration').value

        self.get_logger().info(f'Fall Judgement Node: threshold={self.THRESHOLD}, event={self.EVENT_DURATION}s, cooldown={self.COOLDOWN_DURATION}s')

    def listener_callback(self, msg):
        # 휴지기(이벤트 중 포함)일 경우 데이터 무시
        if self.is_paused:
            return

        # 낙상 판단 로직
        if msg.data == "Lying":
            self.lying_count += 1
            if self.lying_count % 10 == 0:
                self.get_logger().info(f'Lying sequence: {self.lying_count}/{self.THRESHOLD}')
        else:
            self.lying_count = 0

        # 임계치 도달 시
        if self.lying_count >= self.THRESHOLD:
            self.trigger_fall_event()

    def trigger_fall_event(self):
        self.get_logger().warn('FALL ACCIDENT DETECTED! Publishing True.')
        self.is_paused = True
        self.lying_count = 0
        
        # 1. 즉시 True 발행 (한 번만)
        self.publish_status(True)

        # 2. 5초 뒤 False로 변경하는 타이머 설정
        self.timer = self.create_timer(self.EVENT_DURATION, self.reset_to_false)

    def reset_to_false(self):
        # 타이머 중지 및 제거
        if self.timer is not None:
            self.timer.cancel()
            self.destroy_timer(self.timer)
            self.timer = None

        # 3. False 발행 (한 번만)
        self.get_logger().info('Event duration ended. Publishing False and entering cooldown.')
        self.publish_status(False)

        # 4. 10초 휴지기 타이머 시작
        self.cooldown_timer = self.create_timer(self.COOLDOWN_DURATION, self.end_cooldown)

    def end_cooldown(self):
        # 휴지기 타이머 중지 및 제거
        if self.cooldown_timer is not None:
            self.cooldown_timer.cancel()
            self.destroy_timer(self.cooldown_timer)
            self.cooldown_timer = None

        self.is_paused = False
        self.get_logger().info('Cooldown finished. Resuming detection.')

    def publish_status(self, status):
        msg = Bool()
        msg.data = status
        self.publisher_.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = FallJudgementNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()

