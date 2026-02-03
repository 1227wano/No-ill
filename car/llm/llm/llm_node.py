# ~/ros2_ws/src/llm/llm/llm_node.py
import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import requests

class NoilLLMNode(Node):
    def __init__(self):
        super().__init__('llm_node')
        
        # 명세에 따른 토픽 구독 및 발행
        self.subscription = self.create_subscription(String, 'stt_result', self.stt_callback, 10)
        self.publisher = self.create_publisher(String, 'llm_response', 10)
        
        # 서버 설정
        self.auth_url = "http://i14a301.p.ssafy.io:8080/api/auth/pets/login"
        self.talk_url = "http://i14a301.p.ssafy.io:8080/api/conversations/talk"
        self.pet_id = "N0111"
        self.access_token = None
        
        # JWT 토큰 발급
        self.get_jwt_token()
        
        self.get_logger().info("★★★ LLM 통신 노드 가동 ★★★")
    
    def get_jwt_token(self):
        """서버로부터 JWT 토큰 발급"""
        try:
            payload = {"petId": self.pet_id}
            response = requests.post(self.auth_url, json=payload, timeout=10)
            
            if response.status_code == 200:
                self.access_token = response.json().get('accessToken')
                self.get_logger().info(f"✓ JWT 토큰 발급 성공")
            else:
                self.get_logger().error(f"✗ JWT 토큰 발급 실패 (코드: {response.status_code})")
        except Exception as e:
            self.get_logger().error(f"✗ JWT 토큰 발급 오류: {e}")
    
    def stt_callback(self, msg):
        user_text = msg.data
        self.get_logger().info(f"STT 수신: {user_text} -> 서버 요청 중...")
        
        if not self.access_token:
            self.get_logger().error("✗ 토큰이 없습니다. 서버 요청 불가")
            return
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.access_token}"
        }
        
        payload = {
            "petId": self.pet_id,
            "content": user_text
        }
        
        try:
            response = requests.post(self.talk_url, headers=headers, json=payload, timeout=15)
            
            if response.status_code == 200:
                reply = response.json().get('reply')
                self.get_logger().info(f"서버 응답 성공: {reply}")
                
                # TTS로 결과 발행
                res_msg = String()
                res_msg.data = reply
                self.publisher.publish(res_msg)
            else:
                self.get_logger().error(f"서버 요청 실패 (코드: {response.status_code})")
        except Exception as e:
            self.get_logger().error(f"서버 통신 오류: {e}")

def main(args=None):
    rclpy.init(args=args)
    node = NoilLLMNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()