#!/usr/bin/env python3
"""
낙상 사고 판단 노드

기능:
- YOLO에서 "lying" 연속 감지 시 낙상으로 판단
- 30프레임 연속 "lying" 감지 → 낙상 확정
- 10초 쿨다운 후 재감지 가능

토픽:
- 구독: /object_type (String) - YOLO 감지 결과
- 발행: /check_accident (Bool) - 낙상 사고 여부
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Bool
from typing import Optional


class FallJudgementNode(Node):
    """낙상 사고 판단 노드

    연속 "lying" 감지를 통한 낙상 판단:
    - 30프레임 연속 감지 → 낙상 확정
    - 중간에 다른 타입 감지 → 카운트 리셋
    - 낙상 확정 후 10초 쿨다운
    """

    # 설정 상수
    LYING_THRESHOLD = 30        # 낙상 판단 임계값 (프레임)
    COOLDOWN_SECONDS = 10.0     # 재감지 쿨다운 (초)
    LOG_INTERVAL = 10           # 로그 출력 간격 (프레임)

    def __init__(self):
        super().__init__('fall_judgement_node')

        # 상태 변수
        self.lying_count = 0
        self.event_triggered = False
        self.reset_timer: Optional[rclpy.timer.Timer] = None

        # ROS2 인터페이스
        self._init_subscriber()
        self._init_publisher()

        self.get_logger().info(
            f'[FALL] Started | threshold={self.LYING_THRESHOLD}frames | cooldown={self.COOLDOWN_SECONDS}s'
        )

    # =====================================================
    # 초기화
    # =====================================================

    def _init_subscriber(self):
        """구독자 초기화"""
        self.sub_object_type = self.create_subscription(
            String,
            'object_type',
            self._object_type_callback,
            10
        )

    def _init_publisher(self):
        """발행자 초기화"""
        self.pub_check_accident = self.create_publisher(
            Bool,
            'check_accident',
            10
        )

    # =====================================================
    # 콜백
    # =====================================================

    def _object_type_callback(self, msg: String):
        """객체 타입 콜백

        "lying" 연속 감지 카운트
        다른 타입 감지 시 리셋
        """
        # 이벤트 발생 중이면 무시
        if self.event_triggered:
            return

        object_type = msg.data

        if object_type == "lying":
            # lying 카운트 증가
            self.lying_count += 1

            # 주기적 로그 (임계값 도달 직전만)
            if self.lying_count == self.LYING_THRESHOLD - 1:
                self.get_logger().info(
                    f'[FALL] Lying sequence: {self.lying_count}/{self.LYING_THRESHOLD}'
                )

            # 임계값 도달
            if self.lying_count >= self.LYING_THRESHOLD:
                self._trigger_fall_event()
        else:
            # 다른 타입: 카운트 리셋
            if self.lying_count > 0:
                self.get_logger().debug(
                    f'Sequence broken at {self.lying_count}, resetting'
                )
                self.lying_count = 0

    # =====================================================
    # 낙상 이벤트 처리
    # =====================================================

    def _trigger_fall_event(self):
        """낙상 이벤트 트리거

        1. check_accident=True 발행
        2. 상태 플래그 설정
        3. 쿨다운 타이머 시작
        """
        self.get_logger().warn('[FALL] FALL ACCIDENT DETECTED')

        # 상태 변경
        self.event_triggered = True
        self.lying_count = 0

        # check_accident = True 발행 (한 번만)
        accident_msg = Bool()
        accident_msg.data = True
        self.pub_check_accident.publish(accident_msg)

        # 기존 타이머 취소
        if self.reset_timer is not None:
            self.reset_timer.cancel()

        # 쿨다운 타이머 시작
        self.reset_timer = self.create_timer(
            self.COOLDOWN_SECONDS,
            self._reset_event_flag
        )

        self.get_logger().info(f'[FALL] Cooldown {self.COOLDOWN_SECONDS}s')

    def _reset_event_flag(self):
        """이벤트 플래그 리셋 (쿨다운 종료)

        10초 후 다시 감지 가능하도록 플래그 해제
        """
        # 타이머 정리
        if self.reset_timer is not None:
            self.reset_timer.cancel()
            self.reset_timer = None

        # 플래그 해제
        self.event_triggered = False

        self.get_logger().info('[FALL] Detection re-enabled')


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
