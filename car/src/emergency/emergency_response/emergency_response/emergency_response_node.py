#!/usr/bin/env python3
"""
응급 대응 노드

기능:
- 낙상 지점 도착 시 자동 응급 프로세스 시작
- 환자 상태 확인 (최대 5회 시도)
- 응답 없으면 자동 신고 및 캡처
- 응답 있으면 정상 복귀

상태 머신:
  IDLE → ARRIVED → ASKING(×5) → REPORTING → COOLDOWN → IDLE
                       ↓
                   RESPONDED → END → COOLDOWN → IDLE

토픽:
- 구독: /fall_arrived (Bool) - 낙상 지점 도착
       /emergency_stt_result (String) - 환자 응답 (STT)
       /emergency_tts_done (Bool) - TTS 완료
- 발행: /tts_trigger (String) - TTS 출력 요청
       /capture_command (Bool) - 캡처 명령
       /check_accident (Bool) - 사고 상태
       /force_listen (Bool) - STT 강제 청취
       /is_chatting (Bool) - 대화 상태 (주행 제어)
       /fall_arrived (Bool) - 낙상 상태 리셋
"""

import rclpy
from rclpy.node import Node
from rclpy.timer import Timer
from std_msgs.msg import Bool, String
from typing import Optional
from enum import Enum, auto


class EmergencyState(Enum):
    """응급 대응 상태"""
    IDLE = auto()          # 대기
    ARRIVED = auto()       # 도착
    ASKING = auto()        # 질문 중
    WAITING = auto()       # 응답 대기
    REPORTING = auto()     # 신고 중
    ENDING = auto()        # 종료 중
    COOLDOWN = auto()      # 쿨다운


class EmergencyResponseNode(Node):
    """응급 대응 시퀀스 제어 노드

    낙상 감지 후 환자 상태 확인 및 신고 자동화
    """

    # 설정 상수
    MAX_ATTEMPTS = 5                # 최대 질문 시도 횟수
    RESPONSE_TIMEOUT = 5.0          # 응답 대기 시간 (초)
    TTS_DELAY = 0.1                 # TTS 준비 지연 (초)
    CAPTURE_DELAY = 0.5             # 캡처 대기 시간 (초)
    COOLDOWN_DURATION = 3600.0      # 쿨다운 시간 (1시간)

    # TTS 메시지
    MSG_QUESTION = "괜찮습니까?"
    MSG_CONFIRMED = "네, 괜찮으시군요!"
    MSG_REPORTING = "신고를 완료했습니다."

    # 긍정 응답 키워드
    POSITIVE_KEYWORDS = ["응", "어", "괜찮", "됐", "네", "예"]

    def __init__(self):
        super().__init__('emergency_response_node')

        # 상태 변수
        self.state = EmergencyState.IDLE
        self.attempt_count = 0

        # 타이머 관리
        self.response_timer: Optional[Timer] = None
        self.cooldown_timer: Optional[Timer] = None
        self.delay_timer: Optional[Timer] = None

        # ROS2 인터페이스
        self._init_subscribers()
        self._init_publishers()

        self.get_logger().info(
            f'[EMERGENCY] Started | max_attempts={self.MAX_ATTEMPTS} | '
            f'timeout={self.RESPONSE_TIMEOUT}s | cooldown={self.COOLDOWN_DURATION/60:.0f}min'
        )

    # =====================================================
    # 초기화
    # =====================================================

    def _init_subscribers(self):
        """구독자 초기화"""
        self.sub_arrived = self.create_subscription(
            Bool, 'fall_arrived', self._arrived_callback, 10
        )
        self.sub_stt = self.create_subscription(
            String, 'emergency_stt_result', self._stt_callback, 10
        )
        self.sub_emergency_tts_done = self.create_subscription(
            Bool, 'emergency_tts_done', self._emergency_tts_done_callback, 10
        )

    def _init_publishers(self):
        """발행자 초기화"""
        self.pub_tts_trigger = self.create_publisher(String, 'tts_trigger', 10)
        self.pub_capture = self.create_publisher(Bool, 'capture_command', 10)
        self.pub_check_accident = self.create_publisher(Bool, 'check_accident', 10)
        self.pub_force_listen = self.create_publisher(Bool, 'force_listen', 10)
        self.pub_is_chatting = self.create_publisher(Bool, 'is_chatting', 10)
        self.pub_fall_arrived = self.create_publisher(Bool, 'fall_arrived', 10)

    # =====================================================
    # 콜백
    # =====================================================

    def _arrived_callback(self, msg: Bool):
        """낙상 지점 도착 콜백"""
        if msg.data and self.state == EmergencyState.IDLE:
            self.get_logger().warn('[EMERGENCY] PROCESS STARTED')

            self._transition_to(EmergencyState.ARRIVED)
            self.attempt_count = 0

            # TTS 준비 지연 후 시작
            self._cancel_timer('delay')
            self.delay_timer = self.create_timer(
                self.TTS_DELAY,
                self._start_emergency_sequence
            )

    def _emergency_tts_done_callback(self, msg: Bool):
        """TTS 완료 콜백 (응급 모드)"""
        if msg.data and self.state == EmergencyState.ASKING:
            self.get_logger().info('[EMERGENCY] TTS done, listening...')

            # STT 강제 청취 활성화
            self._set_force_listen(True)

            # 응답 대기 상태로 전환
            self._transition_to(EmergencyState.WAITING)

            # 응답 타임아웃 타이머 시작
            self._cancel_timer('response')
            self.response_timer = self.create_timer(
                self.RESPONSE_TIMEOUT,
                self._check_response_timeout
            )

    def _stt_callback(self, msg: String):
        """환자 응답 콜백 (STT)"""
        if self.state != EmergencyState.WAITING:
            return

        user_text = msg.data
        self.get_logger().info(f'[EMERGENCY] Patient: "{user_text}"')

        # 긍정 응답 키워드 확인
        if self._is_positive_response(user_text):
            self._handle_positive_response()
        else:
            self.get_logger().debug('[EMERGENCY] No keyword match, waiting...')

    # =====================================================
    # 상태 머신 로직
    # =====================================================

    def _start_emergency_sequence(self):
        """응급 시퀀스 시작 (지연 후)"""
        self._cancel_timer('delay')

        # 주행 정지 (chat_stop_gate 활성화)
        self._set_is_chatting(True)

        # 첫 질문 시작
        self._ask_patient()

    def _ask_patient(self):
        """환자에게 질문"""
        # 최대 시도 횟수 초과
        if self.attempt_count >= self.MAX_ATTEMPTS:
            self.get_logger().warn(
                f'⚠️  No response after {self.MAX_ATTEMPTS} attempts. Reporting...'
            )
            self._report_accident()
            return

        self.attempt_count += 1
        self.get_logger().info(
            f'[EMERGENCY] Asking patient ({self.attempt_count}/{self.MAX_ATTEMPTS})'
        )

        # 질문 중 상태로 전환
        self._transition_to(EmergencyState.ASKING)

        # TTS 출력 중 STT 차단
        self._set_force_listen(False)

        # TTS 트리거
        self._trigger_tts(self.MSG_QUESTION)

    def _check_response_timeout(self):
        """응답 타임아웃 체크 (5초 후)"""
        self._cancel_timer('response')

        if self.state == EmergencyState.WAITING:
            self.get_logger().info('⏰ No response detected. Retrying...')
            self._ask_patient()

    def _handle_positive_response(self):
        """긍정 응답 처리"""
        self._cancel_timer('response')

        self.get_logger().info('[EMERGENCY] Positive response detected')

        # 확인 메시지 출력
        self._trigger_tts(self.MSG_CONFIRMED)

        # 종료 처리
        self._end_emergency()

    def _report_accident(self):
        """사고 신고 프로세스"""
        self._transition_to(EmergencyState.REPORTING)

        self.get_logger().warn('[EMERGENCY] REPORTING ACCIDENT')

        # 1. 캡처 명령
        self._trigger_capture()

        # 2. 신고 완료 TTS
        self._trigger_tts(self.MSG_REPORTING)

        # 3. 캡처 완료 대기 후 종료
        self._cancel_timer('delay')
        self.delay_timer = self.create_timer(
            self.CAPTURE_DELAY,
            self._end_emergency
        )

    def _end_emergency(self):
        """응급 프로세스 종료"""
        self._cancel_timer('delay')

        self._transition_to(EmergencyState.ENDING)

        self.get_logger().info('[EMERGENCY] Process ended, entering cooldown')

        # 타이머 정리
        self._cancel_timer('response')

        # 상태 초기화
        self.attempt_count = 0

        # STT 강제 청취 해제
        self._set_force_listen(False)

        # 주행 재개
        self._set_is_chatting(False)

        # check_accident = False
        self._set_check_accident(False)

        # tts_node 리셋
        self._reset_fall_arrived()

        # COOLDOWN 진입
        self._start_cooldown()

    def _start_cooldown(self):
        """쿨다운 시작 (1시간)"""
        self._transition_to(EmergencyState.COOLDOWN)

        self._cancel_timer('cooldown')
        self.cooldown_timer = self.create_timer(
            self.COOLDOWN_DURATION,
            self._cooldown_done
        )

        self.get_logger().info(
            f'[EMERGENCY] Cooldown {self.COOLDOWN_DURATION/60:.0f}min'
        )

    def _cooldown_done(self):
        """쿨다운 완료"""
        self._cancel_timer('cooldown')

        self._transition_to(EmergencyState.IDLE)

        self.get_logger().info('[EMERGENCY] Cooldown finished, ready')

    # =====================================================
    # 헬퍼 함수
    # =====================================================

    def _transition_to(self, new_state: EmergencyState):
        """상태 전환"""
        old_state = self.state
        self.state = new_state

        self.get_logger().debug(
            f'State transition: {old_state.name} → {new_state.name}'
        )

    def _is_positive_response(self, text: str) -> bool:
        """긍정 응답 여부 확인"""
        return any(keyword in text for keyword in self.POSITIVE_KEYWORDS)

    def _cancel_timer(self, timer_name: str):
        """타이머 취소"""
        timer_map = {
            'response': 'response_timer',
            'cooldown': 'cooldown_timer',
            'delay': 'delay_timer'
        }

        attr_name = timer_map.get(timer_name)
        if attr_name:
            timer = getattr(self, attr_name, None)
            if timer is not None:
                timer.cancel()
                setattr(self, attr_name, None)

    # =====================================================
    # 발행 헬퍼
    # =====================================================

    def _trigger_tts(self, text: str):
        """TTS 출력 트리거"""
        msg = String()
        msg.data = text
        self.pub_tts_trigger.publish(msg)

        self.get_logger().debug(f'TTS triggered: "{text}"')

    def _trigger_capture(self):
        """캡처 명령 발행"""
        msg = Bool()
        msg.data = True
        self.pub_capture.publish(msg)

        self.get_logger().info('[EMERGENCY] Capture sent')

    def _set_force_listen(self, enable: bool):
        """STT 강제 청취 설정"""
        msg = Bool()
        msg.data = enable
        self.pub_force_listen.publish(msg)

        status = "enabled" if enable else "disabled"
        self.get_logger().debug(f'Force listen {status}')

    def _set_is_chatting(self, chatting: bool):
        """대화 상태 설정 (주행 제어)"""
        msg = Bool()
        msg.data = chatting
        self.pub_is_chatting.publish(msg)

        status = "active" if chatting else "inactive"
        self.get_logger().debug(f'Chat mode {status}')

    def _set_check_accident(self, accident: bool):
        """사고 상태 설정"""
        msg = Bool()
        msg.data = accident
        self.pub_check_accident.publish(msg)

        status = "active" if accident else "cleared"
        self.get_logger().debug(f'Accident status {status}')

    def _reset_fall_arrived(self):
        """낙상 도착 상태 리셋"""
        msg = Bool()
        msg.data = False
        self.pub_fall_arrived.publish(msg)

        self.get_logger().debug('Fall arrived status reset')


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
