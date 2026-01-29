#!/usr/bin/env python3
import math
import rclpy
from rclpy.node import Node
from std_msgs.msg import Float32


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


class SteerFromSaram(Node):
    """
    Subscribes:
      - /saram_x (Float32): target x pixel
      - /saram_y (Float32): target y pixel (optional, for debug)

    Publishes:
      - /steer_track (Float32): steering command in [-steer_max, +steer_max]
    """

    def __init__(self):
        super().__init__("steer_from_saram")

        # --- Params (튜닝은 여기만 건드리면 됨) ---
        self.declare_parameter("image_width", 640.0)
        self.declare_parameter("center_offset_px", 0.0)      # 카메라 중심 보정 필요하면 사용
        self.declare_parameter("deadband_px", 20.0)          # 중앙 근처면 steer=0
        self.declare_parameter("k_p", 1.2)                   # 비례게인(픽셀 오차→steer)
        self.declare_parameter("steer_max", 1.0)             # 최종 steer 제한
        self.declare_parameter("ema_alpha", 0.25)            # 0~1, 낮을수록 더 부드러움
        self.declare_parameter("max_delta_per_cycle", 0.05)  # 한 주기당 steer 변화 제한
        self.declare_parameter("timeout_sec", 0.7)           # 감지 끊김 판단
        self.declare_parameter("control_hz", 20.0)           # 계산/출력 주기
        self.declare_parameter("invert", False)              # 좌/우 반대면 True

        self.image_width = float(self.get_parameter("image_width").value)
        self.center_offset_px = float(self.get_parameter("center_offset_px").value)
        self.deadband_px = float(self.get_parameter("deadband_px").value)
        self.k_p = float(self.get_parameter("k_p").value)
        self.steer_max = float(self.get_parameter("steer_max").value)
        self.ema_alpha = float(self.get_parameter("ema_alpha").value)
        self.max_delta = float(self.get_parameter("max_delta_per_cycle").value)
        self.timeout_sec = float(self.get_parameter("timeout_sec").value)
        self.control_hz = float(self.get_parameter("control_hz").value)
        self.invert = bool(self.get_parameter("invert").value)

        # --- State ---
        self.last_x = None
        self.last_y = None
        self.last_seen_time = self.get_clock().now()
        self.steer_prev = 0.0
        self.steer_ema = 0.0

        # --- I/O ---
        self.sub_x = self.create_subscription(Float32, "/saram_x", self.cb_x, 10)
        self.sub_y = self.create_subscription(Float32, "/saram_y", self.cb_y, 10)
        self.pub = self.create_publisher(Float32, "/steer_track", 10)

        period = 1.0 / max(1.0, self.control_hz)
        self.timer = self.create_timer(period, self.on_timer)

        self.get_logger().info(
            f"SteerFromSaram started: width={self.image_width}, deadband={self.deadband_px}, "
            f"k_p={self.k_p}, steer_max={self.steer_max}, hz={self.control_hz}"
        )

    def cb_x(self, msg: Float32):
        self.last_x = float(msg.data)
        self.last_seen_time = self.get_clock().now()

    def cb_y(self, msg: Float32):
        self.last_y = float(msg.data)
        self.last_seen_time = self.get_clock().now()

    def on_timer(self):
        now = self.get_clock().now()
        dt = (now - self.last_seen_time).nanoseconds / 1e9

        # 감지 끊김이면 steer를 0으로 천천히 복귀
        if self.last_x is None or dt > self.timeout_sec:
            target = 0.0
        else:
            cx = (self.image_width / 2.0) + self.center_offset_px
            err_px = (self.last_x - cx)

            # deadband
            if abs(err_px) < self.deadband_px:
                err_px = 0.0

            # 픽셀 오차를 [-1,1] 범위로 정규화(대략)
            # width/2 픽셀 오차가 1.0이 되도록
            err_norm = err_px / max(1.0, (self.image_width / 2.0))

            # P 제어
            target = self.k_p * err_norm

            if self.invert:
                target *= -1.0

            target = clamp(target, -self.steer_max, self.steer_max)

        # EMA 필터
        a = clamp(self.ema_alpha, 0.0, 1.0)
        self.steer_ema = (a * target) + ((1.0 - a) * self.steer_ema)

        # 레이트 리밋(급변 방지)
        delta = self.steer_ema - self.steer_prev
        delta = clamp(delta, -self.max_delta, self.max_delta)
        steer_cmd = self.steer_prev + delta
        steer_cmd = clamp(steer_cmd, -self.steer_max, self.steer_max)

        self.steer_prev = steer_cmd

        out = Float32()
        out.data = float(steer_cmd)
        self.pub.publish(out)

        # 로그(너무 시끄러우면 1초에 1번만 찍게 바꿔도 됨)
        if self.last_x is None:
            self.get_logger().info(f"no target -> steer={steer_cmd:+.3f}")
        else:
            self.get_logger().info(
                f"x={self.last_x:.1f} y={self.last_y if self.last_y is not None else -1:.1f} "
                f"dt={dt:.2f}s -> steer={steer_cmd:+.3f}"
            )


def main():
    rclpy.init()
    node = SteerFromSaram()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()

