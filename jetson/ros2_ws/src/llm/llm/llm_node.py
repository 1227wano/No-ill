# ~/ros2_ws/src/llm/llm/llm_node.py
import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import requests
import os

class NoilLLMNode(Node):
    def __init__(self):
        super().__init__('llm_node')
        # 명세에 따른 토픽 구독 및 발행
        self.subscription = self.create_subscription(String, 'stt_result', self.stt_callback, 10)
        self.publisher = self.create_publisher(String, 'llm_response', 10)

        # API 설정 (환경변수에서 로드)
        self.api_key = os.environ.get('LLM_API_KEY', '')
        self.api_url = os.environ.get('LLM_API_URL', 'https://gms.ssafy.io/gmsapi/api.openai.com/v1/chat/completions')

        if not self.api_key:
            self.get_logger().error("LLM_API_KEY 환경변수가 설정되지 않았습니다!")

        self.get_logger().info("★★★ LLM 통신 노드 가동 ★★★")

    def stt_callback(self, msg):
        user_text = msg.data
        self.get_logger().info(f"STT 수신: {user_text} -> API 요청 중...")
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }
        
        system_content = (
            "당신은 친절한 인공지능 도우미입니다. 다음 지침을 지켜주세요. "
            "1. 모든 답변은 한국어로 하며, 2~3문장 내외로 간결하게 답변하세요. "
            "2. 입력값은 STT 결과이므로 오타가 있을 수 있습니다. 문맥을 파악해 자연스럽게 보정하세요. "
            "3. 구어체 대답 형식으로 답변하세요."
        )

        payload = {
            "model": "gpt-4.1",
            "messages": [
                {"role": "developer", "content": system_content},
                {"role": "user", "content": user_text}
            ]
        }

        try:
            response = requests.post(self.api_url, headers=headers, json=payload, timeout=15)
            
            if response.status_code == 200:
                answer = response.json()['choices'][0]['message']['content']
                self.get_logger().info(f"API 응답 성공: {answer}")
                
                # 결과 발행
                res_msg = String()
                res_msg.data = answer
                self.publisher.publish(res_msg)
            else:
                self.get_logger().error(f"API 호출 실패 (코드: {response.status_code})")
        except Exception as e:
            self.get_logger().error(f"API 통신 오류: {e}")

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
