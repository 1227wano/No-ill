import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool
import requests
import os

class ImageUploadNode(Node):
    def __init__(self):
        super().__init__('upload_accident_node')
        
        # Subscriber: accident_cap 토픽 구독
        self.sub_cap = self.create_subscription(
            Bool, 'accident_cap', self.upload_callback, 10)
        
        # 고정된 이미지 경로
        self.image_path = os.path.expanduser('~/Downloads/N0111.jpg')
        
        # 업로드 엔드포인트
        self.upload_url = "http://i14a301.p.ssafy.io:8080/api/events/report"
        
        self.get_logger().info('★★★ Upload Accident Node Started ★★★')
        self.get_logger().info(f'Monitoring: {self.image_path}')
        self.get_logger().info(f'Upload URL: {self.upload_url}')
    
    def upload_callback(self, msg):
        """accident_cap이 True일 때 이미지 업로드"""
        if msg.data is True:
            self.get_logger().info('accident_cap = True. Starting upload...')
            
            # 파일 존재 확인
            if not os.path.exists(self.image_path):
                self.get_logger().error(f'File not found: {self.image_path}')
                return
            
            try:
                # POST 요청으로 이미지 업로드
                with open(self.image_path, 'rb') as f:
                    files = {'file': ('N0111.jpg', f, 'image/jpeg')}
                    response = requests.post(
                        self.upload_url, 
                        files=files, 
                        timeout=10
                    )
                
                if response.status_code == 200:
                    self.get_logger().info('✓ Upload successful!')
                    self.get_logger().info(f'Response: {response.text}')
                else:
                    self.get_logger().error(
                        f'✗ Upload failed (status: {response.status_code})')
                    self.get_logger().error(f'Response: {response.text}')
                    
            except requests.exceptions.Timeout:
                self.get_logger().error('✗ Upload timeout (10s)')
            except Exception as e:
                self.get_logger().error(f'✗ Upload error: {e}')

def main(args=None):
    rclpy.init(args=args)
    node = ImageUploadNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
