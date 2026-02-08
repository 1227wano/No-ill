#!/usr/bin/env python3
"""
사고 이미지 업로드 노드

기능:
- 낙상 사고 발생 시 캡처된 이미지를 서버에 업로드
- 최대 3회 재시도
- 타임아웃 및 에러 처리

토픽:
- 구독: /accident_cap (Bool) - 캡처 완료 신호
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool
import requests
import os
import time
from typing import Optional, Tuple  # Python 3.8 호환
from pathlib import Path


class ImageUploadNode(Node):
    """사고 이미지 서버 업로드 노드

    YOLO 감지기에서 캡처한 낙상 이미지를
    백엔드 서버로 업로드
    """

    # 설정 상수
    MAX_RETRIES = 3             # 최대 재시도 횟수
    RETRY_DELAY = 1.0           # 재시도 간격 (초)
    REQUEST_TIMEOUT = 10.0      # 요청 타임아웃 (초)

    # 파일 설정
    DEFAULT_IMAGE_NAME = 'N0111.jpg'
    DEFAULT_SAVE_DIR = '~/Downloads'

    # 서버 설정
    DEFAULT_UPLOAD_URL = "http://i14a301.p.ssafy.io:8080/api/events/report"

    def __init__(self):
        super().__init__('upload_accident_node')

        # 파라미터 선언 및 로드
        self._declare_parameters()
        self._load_parameters()

        # 구독자 초기화
        self._init_subscriber()

        self._log_configuration()

    # =====================================================
    # 초기화
    # =====================================================

    def _declare_parameters(self):
        """파라미터 선언"""
        self.declare_parameter('image_name', self.DEFAULT_IMAGE_NAME)
        self.declare_parameter('save_directory', self.DEFAULT_SAVE_DIR)
        self.declare_parameter('upload_url', self.DEFAULT_UPLOAD_URL)
        self.declare_parameter('max_retries', self.MAX_RETRIES)
        self.declare_parameter('retry_delay', self.RETRY_DELAY)
        self.declare_parameter('request_timeout', self.REQUEST_TIMEOUT)

    def _load_parameters(self):
        """파라미터 로드"""
        image_name = self.get_parameter('image_name').as_string()
        save_dir = self.get_parameter('save_directory').as_string()

        # 이미지 경로 구성
        self.image_path = Path(os.path.expanduser(save_dir)) / image_name

        # 서버 URL
        self.upload_url = self.get_parameter('upload_url').as_string()

        # 재시도 설정
        self.max_retries = self.get_parameter('max_retries').as_integer()
        self.retry_delay = self.get_parameter('retry_delay').as_double()
        self.request_timeout = self.get_parameter('request_timeout').as_double()

    def _init_subscriber(self):
        """구독자 초기화"""
        self.sub_accident_cap = self.create_subscription(
            Bool,
            'accident_cap',
            self._accident_cap_callback,
            10
        )

    def _log_configuration(self):
        """설정 로그"""
        self.get_logger().info('=' * 50)
        self.get_logger().info('★★★ Upload Accident Node Started ★★★')
        self.get_logger().info('=' * 50)
        self.get_logger().info(f'Image path: {self.image_path}')
        self.get_logger().info(f'Upload URL: {self.upload_url}')
        self.get_logger().info(f'Max retries: {self.max_retries}')
        self.get_logger().info('=' * 50)

    # =====================================================
    # 콜백
    # =====================================================

    def _accident_cap_callback(self, msg: Bool):
        """캡처 완료 콜백

        accident_cap = True 시 이미지 업로드 수행
        """
        if not msg.data:
            return

        self.get_logger().info('=' * 50)
        self.get_logger().info('📤 accident_cap = True. Starting upload...')
        self.get_logger().info('=' * 50)

        # 업로드 시도
        success = self._upload_image_with_retry()

        if success:
            self.get_logger().info('✅ Image upload completed successfully')
        else:
            self.get_logger().error('❌ Image upload failed after all retries')

    # =====================================================
    # 업로드 로직
    # =====================================================

    def _upload_image_with_retry(self) -> bool:
        """재시도를 포함한 이미지 업로드

        Returns:
            bool: 업로드 성공 여부
        """
        # 파일 존재 확인
        if not self.image_path.exists():
            self.get_logger().error(f'❌ File not found: {self.image_path}')
            return False

        # 파일 크기 확인
        file_size = self.image_path.stat().st_size
        self.get_logger().info(f'📁 File size: {file_size / 1024:.2f} KB')

        # 재시도 루프
        for attempt in range(1, self.max_retries + 1):
            self.get_logger().info(
                f'🔄 Upload attempt {attempt}/{self.max_retries}...'
            )

            # 업로드 시도
            success, status_code, response_text = self._upload_image()

            if success:
                self.get_logger().info(f'✅ Upload successful (status: {status_code})')
                if response_text:
                    self.get_logger().info(f'Response: {response_text}')
                return True

            # 실패 로그
            self.get_logger().warn(
                f'⚠️  Upload failed (attempt {attempt}/{self.max_retries}, '
                f'status: {status_code if status_code else "N/A"})'
            )

            # 재시도 대기
            if attempt < self.max_retries:
                self.get_logger().info(
                    f'⏳ Retrying in {self.retry_delay} seconds...'
                )
                time.sleep(self.retry_delay)

        return False

    def _upload_image(self) -> Tuple[bool, Optional[int], Optional[str]]:
        """이미지 업로드 (단일 시도)

        Returns:
            Tuple[bool, Optional[int], Optional[str]]:
                (성공 여부, 상태 코드, 응답 텍스트)
        """
        try:
            # 파일 열기 및 업로드
            with open(self.image_path, 'rb') as f:
                files = {
                    'file': (
                        self.image_path.name,
                        f,
                        'image/jpeg'
                    )
                }

                response = requests.post(
                    self.upload_url,
                    files=files,
                    timeout=self.request_timeout
                )

            # 성공 여부 확인 (200번대 상태 코드)
            success = 200 <= response.status_code < 300

            return success, response.status_code, response.text

        except requests.exceptions.Timeout:
            self.get_logger().error(
                f'⏱️  Request timeout ({self.request_timeout}s)'
            )
            return False, None, None

        except requests.exceptions.ConnectionError as e:
            self.get_logger().error(f'🔌 Connection error: {e}')
            return False, None, None

        except requests.exceptions.RequestException as e:
            self.get_logger().error(f'❌ Request error: {e}')
            return False, None, None

        except IOError as e:
            self.get_logger().error(f'📁 File I/O error: {e}')
            return False, None, None

        except Exception as e:
            self.get_logger().error(f'❌ Unexpected error: {type(e).__name__}: {e}')
            return False, None, None


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
