import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
from collections import deque
import time

class FallJudgementNode(Node):
    def __init__(self):
        super().__init__('fall_judgement_node')

        # Subscriber
        self.create_subscription(String, 'object_type', self.listener_callback, 10)

        # Publisher
        self.publisher_ = self.create_publisher(Bool, 'check_accident', 10)

        # 상태 변수
        self.event_triggered = False

        # 설정값
        self.TIME_WINDOW = 5.0  # 5초 윈도우
        self.THRESHOLD = 30    # 5초 내에 30번 lying이면 발동

        # 시간 기반 카운트 (timestamp 저장)
        self.lying_times = deque()

        self.get_logger().info('★★★ Fall Judgement Node Started ★★★')
        self.get_logger().info(f'    Window: {self.TIME_WINDOW}s, Threshold: {self.THRESHOLD}')

    def listener_callback(self, msg):
        # 이미 이벤트 발생했으면 무시
        if self.event_triggered:
            return

        now = time.time()

        # 오래된 기록 제거 (TIME_WINDOW 밖)
        while self.lying_times and (now - self.lying_times[0]) > self.TIME_WINDOW:
            self.lying_times.popleft()

        # lying이면 기록 추가
        if msg.data == "lying":
            self.lying_times.append(now)

            count = len(self.lying_times)
            if count % 10 == 0:
                self.get_logger().info(f'Lying count (in {self.TIME_WINDOW}s): {count}/{self.THRESHOLD}')

        # 임계치 도달 시
        if len(self.lying_times) >= self.THRESHOLD:
            self.trigger_fall_event()

    def trigger_fall_event(self):
        self.get_logger().warn('!!! FALL ACCIDENT DETECTED !!!')
        self.event_triggered = True
        self.lying_times.clear()

        # check_accident = True 발행 (한 번만)
        msg = Bool()
        msg.data = True
        self.publisher_.publish(msg)

        # 10초 후 다시 감지 가능하도록 리셋
        self.create_timer(10.0, self.reset_event_flag)

    def reset_event_flag(self):
        """10초 후 다시 감지 가능"""
        self.event_triggered = False
        self.lying_times.clear()
        self.get_logger().info('Fall detection re-enabled.')

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
