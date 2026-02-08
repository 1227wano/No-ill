#!/usr/bin/env python3
"""
LLM 대화 노드

기능:
- STT 결과를 백엔드 LLM 서버로 전송
- LLM 응답을 TTS로 전달
- JWT 토큰 기반 인증 (자동 재발급)

토픽:
- 구독: /stt_result (String) - 음성 인식 결과
- 발행: /llm_response (String) - LLM 응답
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import requests
from typing import Optional, Dict, Any
from requests.exceptions import RequestException, Timeout, ConnectionError


class NoilLLMNode(Node):
    """백엔드 LLM 서버 통신 노드

    사용자 발화를 서버로 전송하고
    LLM 응답을 받아 TTS로 전달
    """

    # 서버 설정
    DEFAULT_AUTH_URL = "http://i14a301.p.ssafy.io:8080/api/auth/pets/login"
    DEFAULT_TALK_URL = "http://i14a301.p.ssafy.io:8080/api/conversations/talk"
    DEFAULT_PET_ID = "N0111"

    # 타임아웃 설정
    AUTH_TIMEOUT = 10.0      # 인증 타임아웃 (초)
    TALK_TIMEOUT = 15.0      # 대화 타임아웃 (초)

    # 재시도 설정
    MAX_TOKEN_RETRIES = 3    # 토큰 재발급 최대 시도

    def __init__(self):
        super().__init__('llm_node')

        # 파라미터 선언 및 로드
        self._declare_parameters()
        self._load_parameters()

        # 토큰 관리
        self.access_token: Optional[str] = None
        self.token_retry_count = 0

        # ROS2 인터페이스
        self._init_subscriber()
        self._init_publisher()

        # JWT 토큰 발급
        self._obtain_jwt_token()

        self._log_configuration()

    # =====================================================
    # 초기화
    # =====================================================

    def _declare_parameters(self):
        """파라미터 선언"""
        self.declare_parameter('auth_url', self.DEFAULT_AUTH_URL)
        self.declare_parameter('talk_url', self.DEFAULT_TALK_URL)
        self.declare_parameter('pet_id', self.DEFAULT_PET_ID)
        self.declare_parameter('auth_timeout', self.AUTH_TIMEOUT)
        self.declare_parameter('talk_timeout', self.TALK_TIMEOUT)

    def _load_parameters(self):
        """파라미터 로드"""
        self.auth_url = self.get_parameter('auth_url').as_string()
        self.talk_url = self.get_parameter('talk_url').as_string()
        self.pet_id = self.get_parameter('pet_id').as_string()
        self.auth_timeout = self.get_parameter('auth_timeout').as_double()
        self.talk_timeout = self.get_parameter('talk_timeout').as_double()

    def _init_subscriber(self):
        """구독자 초기화"""
        self.sub_stt = self.create_subscription(
            String,
            'stt_result',
            self._stt_callback,
            10
        )

    def _init_publisher(self):
        """발행자 초기화"""
        self.pub_llm_response = self.create_publisher(
            String,
            'llm_response',
            10
        )

    def _log_configuration(self):
        """설정 로그"""
        self.get_logger().info('=' * 50)
        self.get_logger().info('★★★ LLM Communication Node Started ★★★')
        self.get_logger().info('=' * 50)
        self.get_logger().info(f'Pet ID: {self.pet_id}')
        self.get_logger().info(f'Auth URL: {self.auth_url}')
        self.get_logger().info(f'Talk URL: {self.talk_url}')
        self.get_logger().info(f'Token status: {"✅ Valid" if self.access_token else "❌ Invalid"}')
        self.get_logger().info('=' * 50)

    # =====================================================
    # JWT 토큰 관리
    # =====================================================

    def _obtain_jwt_token(self) -> bool:
        """JWT 토큰 발급

        Returns:
            bool: 발급 성공 여부
        """
        if self.token_retry_count >= self.MAX_TOKEN_RETRIES:
            self.get_logger().error(
                f'❌ Token retry limit reached ({self.MAX_TOKEN_RETRIES})'
            )
            return False

        self.token_retry_count += 1

        self.get_logger().info(
            f'🔑 Requesting JWT token (attempt {self.token_retry_count}/{self.MAX_TOKEN_RETRIES})...'
        )

        try:
            payload = {"petId": self.pet_id}

            response = requests.post(
                self.auth_url,
                json=payload,
                timeout=self.auth_timeout
            )

            if response.status_code == 200:
                data = response.json()
                self.access_token = data.get('accessToken')

                if self.access_token:
                    self.token_retry_count = 0  # 성공 시 카운터 리셋
                    self.get_logger().info('✅ JWT token obtained successfully')
                    return True
                else:
                    self.get_logger().error('❌ Token not found in response')
                    return False
            else:
                self.get_logger().error(
                    f'❌ Token request failed (status: {response.status_code})'
                )
                return False

        except Timeout:
            self.get_logger().error(
                f'⏱️  Token request timeout ({self.auth_timeout}s)'
            )
            return False

        except ConnectionError as e:
            self.get_logger().error(f'🔌 Connection error: {e}')
            return False

        except RequestException as e:
            self.get_logger().error(f'❌ Request error: {e}')
            return False

        except Exception as e:
            self.get_logger().error(
                f'❌ Unexpected error: {type(e).__name__}: {e}'
            )
            return False

    def _refresh_token_if_needed(self) -> bool:
        """토큰 재발급 (필요 시)

        Returns:
            bool: 유효한 토큰 확보 여부
        """
        if not self.access_token:
            self.get_logger().warn('⚠️  No token available. Obtaining new token...')
            return self._obtain_jwt_token()

        return True

    # =====================================================
    # 콜백
    # =====================================================

    def _stt_callback(self, msg: String):
        """STT 결과 콜백

        사용자 발화를 LLM 서버로 전송
        """
        user_text = msg.data

        self.get_logger().info('=' * 50)
        self.get_logger().info(f'💬 STT received: "{user_text}"')
        self.get_logger().info('🤖 Requesting LLM response...')

        # 토큰 확인
        if not self._refresh_token_if_needed():
            self.get_logger().error('❌ Token unavailable. Request aborted.')
            return

        # LLM 서버 요청
        success, reply = self._request_llm(user_text)

        if success and reply:
            self.get_logger().info(f'✅ LLM response: "{reply}"')
            self._publish_response(reply)
        else:
            self.get_logger().error('❌ Failed to get LLM response')

        self.get_logger().info('=' * 50)

    # =====================================================
    # LLM 서버 통신
    # =====================================================

    def _request_llm(self, user_text: str) -> tuple:
        """LLM 서버에 대화 요청

        Args:
            user_text: 사용자 발화 텍스트

        Returns:
            tuple: (성공 여부, 응답 텍스트)
        """
        headers = self._build_headers()
        payload = self._build_payload(user_text)

        try:
            response = requests.post(
                self.talk_url,
                headers=headers,
                json=payload,
                timeout=self.talk_timeout
            )

            # 401 Unauthorized: 토큰 만료
            if response.status_code == 401:
                self.get_logger().warn('⚠️  Token expired. Refreshing...')

                if self._obtain_jwt_token():
                    # 토큰 재발급 성공: 재시도
                    headers = self._build_headers()
                    response = requests.post(
                        self.talk_url,
                        headers=headers,
                        json=payload,
                        timeout=self.talk_timeout
                    )
                else:
                    return False, None

            # 200 OK
            if response.status_code == 200:
                data = response.json()
                reply = data.get('reply')
                return True, reply
            else:
                self.get_logger().error(
                    f'❌ Server error (status: {response.status_code})'
                )
                return False, None

        except Timeout:
            self.get_logger().error(
                f'⏱️  Request timeout ({self.talk_timeout}s)'
            )
            return False, None

        except ConnectionError as e:
            self.get_logger().error(f'🔌 Connection error: {e}')
            return False, None

        except RequestException as e:
            self.get_logger().error(f'❌ Request error: {e}')
            return False, None

        except Exception as e:
            self.get_logger().error(
                f'❌ Unexpected error: {type(e).__name__}: {e}'
            )
            return False, None

    def _build_headers(self) -> Dict[str, str]:
        """HTTP 헤더 생성

        Returns:
            Dict: HTTP 헤더
        """
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.access_token}"
        }

    def _build_payload(self, user_text: str) -> Dict[str, str]:
        """요청 페이로드 생성

        Args:
            user_text: 사용자 발화 텍스트

        Returns:
            Dict: 요청 페이로드
        """
        return {
            "petId": self.pet_id,
            "content": user_text
        }

    def _publish_response(self, reply: str):
        """LLM 응답 발행

        Args:
            reply: LLM 응답 텍스트
        """
        msg = String()
        msg.data = reply
        self.pub_llm_response.publish(msg)


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
