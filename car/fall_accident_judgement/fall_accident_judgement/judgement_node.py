import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool

class FallJudgementNode(Node):
    def __init__(self):
        super().__init__('fall_judgement_node')
        
        # Subscriber
        self.create_subscription(String, 'object_type', self.listener_callback, 10)
        
        # Publisher
        self.publisher_ = self.create_publisher(Bool, 'check_accident', 10)
        
        # 상태 변수
        self.lying_count = 0
        self.event_triggered = False
        
        # 설정값
        self.THRESHOLD = 30
        
        self.get_logger().info('★★★ Fall Judgement Node Started ★★★')
    
    def listener_callback(self, msg):
        # 이미 이벤트 발생했으면 무시
        if self.event_triggered:
            return
        
        # 낙상 판단 로직
        if msg.data == "lying":
            self.lying_count += 1
            if self.lying_count % 10 == 0:
                self.get_logger().info(f'Lying sequence: {self.lying_count}/{self.THRESHOLD}')
        else:
            self.lying_count = 0
        
        # 임계치 도달 시
        if self.lying_count >= self.THRESHOLD:
            self.trigger_fall_event()
    
    def trigger_fall_event(self):
        self.get_logger().warn('!!! FALL ACCIDENT DETECTED !!!')
        self.event_triggered = True
        self.lying_count = 0
        
        # check_accident = True 발행 (한 번만)
        msg = Bool()
        msg.data = True
        self.publisher_.publish(msg)
        
        # 10초 후 다시 감지 가능하도록 리셋
        self.create_timer(10.0, self.reset_event_flag)
    
    def reset_event_flag(self):
        """10초 후 다시 감지 가능"""
        self.event_triggered = False
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