/**
 * @file safety_override_node.cpp
 * @brief 장애물 회피 안전 시스템
 *
 * 기능:
 * - LiDAR 기반 실시간 장애물 감지
 * - 거리 기반 다단계 회피 전략
 *   1. > 50cm: 개입 없음
 *   2. 30~50cm: 감속 + 회피 조향
 *   3. < 30cm: 후진 + 반대 방향 조향
 *
 * 우선순위:
 * - twist_mux에서 priority 200 (person보다 높음, chatting보다 낮음)
 *
 * 토픽:
 * - 구독: /scan (LaserScan) - LiDAR 데이터
 * - 발행: /cmd_vel_safety (Twist) - 안전 회피 명령
 */

#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>
#include <geometry_msgs/msg/twist.hpp>

#include <algorithm>
#include <cmath>
#include <limits>
#include <string>
#include <memory>

/**
 * @class SafetyOverrideNode
 * @brief LiDAR 기반 능동 장애물 회피 노드
 *
 * 3섹터 감지:
 * - Front: ±15° (전방)
 * - Left: +10° ~ +200° (좌측)
 * - Right: -200° ~ -10° (우측)
 *
 * 회피 전략:
 * - 좌우 중 더 열린 공간으로 회전
 * - 거리에 비례한 감속 및 회피 강도 조절
 */
class SafetyOverrideNode : public rclcpp::Node {
public:
  SafetyOverrideNode() : Node("safety_override_node") {
    declareParameters();
    initializePublisher();
    initializeSubscriber();
    initializeTimer();

    logConfiguration();
  }

private:
  // =====================================================
  // 초기화 함수들
  // =====================================================

  void declareParameters() {
    // 토픽
    declare_parameter<std::string>("scan_topic", "/scan");
    declare_parameter<std::string>("cmd_topic", "/cmd_vel_safety");

    // 거리 임계값
    declare_parameter<double>("slow_dist", 0.50);      // 감속 시작 거리 (m)
    declare_parameter<double>("reverse_dist", 0.30);   // 후진 시작 거리 (m)

    // 속도 설정
    declare_parameter<double>("min_fwd", 0.30);        // 최소 전진 속도 (m/s)
    declare_parameter<double>("rev_speed", -0.30);     // 후진 속도 (m/s)

    // 회전 설정
    declare_parameter<double>("max_yaw", 1.0);         // 최대 회전 속도 (rad/s)
    declare_parameter<double>("yaw_slow", 0.8);        // 감속 구간 회피 강도
    declare_parameter<double>("yaw_reverse", 0.6);     // 후진 구간 회피 강도

    // 감지 섹터 설정
    declare_parameter<double>("sector_front_deg", 15.0);       // 전방 감지 각도 (±degree)
    declare_parameter<double>("sector_side_min_deg", 10.0);    // 좌우 측면 최소 각도
    declare_parameter<double>("sector_side_max_deg", 200.0);   // 좌우 측면 최대 각도

    // 발행 주기
    declare_parameter<double>("publish_hz", 20.0);
  }

  void initializePublisher() {
    const auto cmd_topic = get_parameter("cmd_topic").as_string();
    pub_cmd_ = create_publisher<geometry_msgs::msg::Twist>(cmd_topic, 10);
  }

  void initializeSubscriber() {
    const auto scan_topic = get_parameter("scan_topic").as_string();

    sub_scan_ = create_subscription<sensor_msgs::msg::LaserScan>(
      scan_topic,
      rclcpp::SensorDataQoS(),
      std::bind(&SafetyOverrideNode::scanCallback, this, std::placeholders::_1)
    );
  }

  void initializeTimer() {
    const double hz = get_parameter("publish_hz").as_double();
    const int period_ms = static_cast<int>(1000.0 / hz);

    timer_ = create_wall_timer(
      std::chrono::milliseconds(period_ms),
      std::bind(&SafetyOverrideNode::timerCallback, this)
    );
  }

  void logConfiguration() {
    const auto scan_topic = get_parameter("scan_topic").as_string();
    const auto cmd_topic = get_parameter("cmd_topic").as_string();
    const double slow_dist = get_parameter("slow_dist").as_double();
    const double reverse_dist = get_parameter("reverse_dist").as_double();

    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Safety Override Node Started");
    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Topics:");
    RCLCPP_INFO(get_logger(), "  scan: %s", scan_topic.c_str());
    RCLCPP_INFO(get_logger(), "  cmd : %s", cmd_topic.c_str());
    RCLCPP_INFO(get_logger(), "Distance thresholds:");
    RCLCPP_INFO(get_logger(), "  Slow down: %.2f m", slow_dist);
    RCLCPP_INFO(get_logger(), "  Reverse  : %.2f m", reverse_dist);
    RCLCPP_INFO(get_logger(), "===========================================");
  }

  // =====================================================
  // 콜백 함수들
  // =====================================================

  /**
   * @brief LiDAR 스캔 콜백
   */
  void scanCallback(const sensor_msgs::msg::LaserScan::SharedPtr msg) {
    last_scan_ = msg;
    got_scan_ = true;
  }

  /**
   * @brief 메인 타이머 콜백
   *
   * LiDAR 데이터를 분석하여 장애물 회피 명령 생성
   */
  void timerCallback() {
    if (!got_scan_ || !last_scan_) {
      return;
    }

    const auto& scan = *last_scan_;

    // 파라미터 로드
    const double slow_dist = get_parameter("slow_dist").as_double();
    const double reverse_dist = get_parameter("reverse_dist").as_double();
    const double min_fwd = get_parameter("min_fwd").as_double();
    const double rev_speed = get_parameter("rev_speed").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();
    const double yaw_slow = get_parameter("yaw_slow").as_double();
    const double yaw_reverse = get_parameter("yaw_reverse").as_double();

    const double front_deg = get_parameter("sector_front_deg").as_double();
    const double side_min_deg = get_parameter("sector_side_min_deg").as_double();
    const double side_max_deg = get_parameter("sector_side_max_deg").as_double();

    // 3섹터 최소 거리 계산
    const double front_dist = getMinRangeInSector(
      scan,
      deg2rad(-front_deg),
      deg2rad(+front_deg)
    );

    const double left_dist = getMinRangeInSector(
      scan,
      deg2rad(+side_min_deg),
      deg2rad(+side_max_deg)
    );

    const double right_dist = getMinRangeInSector(
      scan,
      deg2rad(-side_max_deg),
      deg2rad(-side_min_deg)
    );

    // 전방 안전: slow_dist(50cm)보다 멀면 개입하지 않음
    if (!std::isfinite(front_dist) || front_dist > slow_dist) {
      return;  // 명령 발행하지 않음 → twist_mux가 하위 우선순위 선택
    }

    // 거리 기반 회피 전략 결정
    geometry_msgs::msg::Twist cmd;

    if (front_dist <= reverse_dist) {
      // 위험: 후진 + 반대 방향 회피
      handleEmergencyReverse(cmd, left_dist, right_dist, rev_speed, yaw_reverse, max_yaw);
    } else {
      // 경고: 감속 + 회피 조향
      handleSlowAndAvoid(cmd, front_dist, left_dist, right_dist,
                         slow_dist, reverse_dist, min_fwd, yaw_slow, max_yaw);
    }

    pub_cmd_->publish(cmd);
  }

  // =====================================================
  // 회피 전략 함수들
  // =====================================================

  /**
   * @brief 긴급 후진 처리
   *
   * front_dist <= reverse_dist (30cm) 일 때:
   * - 후진 속도로 이동
   * - 더 열린 방향의 반대쪽으로 회전 (다시 전진 시 회피 경로 확보)
   */
  void handleEmergencyReverse(
    geometry_msgs::msg::Twist& cmd,
    double left_dist,
    double right_dist,
    double rev_speed,
    double yaw_reverse,
    double max_yaw
  ) {
    cmd.linear.x = rev_speed;  // 후진

    // 더 열린 방향으로 회전하되, 반대 방향으로 조향
    // (후진하면서 반대로 틀어야 다시 전진 시 열린 공간으로 향함)
    const double yaw = chooseAvoidanceYaw(left_dist, right_dist, yaw_reverse);
    cmd.angular.z = std::clamp(-yaw, -max_yaw, +max_yaw);

    RCLCPP_WARN_THROTTLE(
      get_logger(),
      *get_clock(),
      1000,  // 1초마다
      "⚠️  Emergency reverse! Distance: %.2f m",
      left_dist  // front_dist 대신 참고용
    );
  }

  /**
   * @brief 감속 및 회피 처리
   *
   * reverse_dist < front_dist <= slow_dist (30~50cm) 일 때:
   * - 거리 비례 감속 (가까울수록 느리게)
   * - 더 열린 공간으로 회전 (가까울수록 강하게)
   */
  void handleSlowAndAvoid(
    geometry_msgs::msg::Twist& cmd,
    double front_dist,
    double left_dist,
    double right_dist,
    double slow_dist,
    double reverse_dist,
    double min_fwd,
    double yaw_slow,
    double max_yaw
  ) {
    // 거리 비율 계산: t=0(30cm, 가까움) ~ t=1(50cm, 멈)
    double t = (front_dist - reverse_dist) / (slow_dist - reverse_dist);
    t = std::clamp(t, 0.0, 1.0);

    // 속도: 가까울수록 느리게 (t가 작을수록 느림)
    cmd.linear.x = min_fwd * t;

    // 회피 yaw: 가까울수록 강하게 (1-t가 클수록 강함)
    const double yaw = chooseAvoidanceYaw(left_dist, right_dist, yaw_slow);
    const double adjusted_yaw = yaw * (1.0 - t);
    cmd.angular.z = std::clamp(adjusted_yaw, -max_yaw, +max_yaw);

    RCLCPP_DEBUG(
      get_logger(),
      "Slow & avoid: dist=%.2f, speed=%.2f, yaw=%.2f",
      front_dist, cmd.linear.x, cmd.angular.z
    );
  }

  // =====================================================
  // 유틸리티 함수들
  // =====================================================

  /**
   * @brief 각도를 라디안으로 변환
   */
  static double deg2rad(double degrees) {
    return degrees * M_PI / 180.0;
  }

  /**
   * @brief 지정된 각도 범위 내 최소 거리 계산
   *
   * @param scan LiDAR 스캔 데이터
   * @param angle_min 최소 각도 (rad)
   * @param angle_max 최대 각도 (rad)
   * @return 최소 거리 (m), 유효한 데이터 없으면 infinity
   */
  double getMinRangeInSector(
    const sensor_msgs::msg::LaserScan& scan,
    double angle_min,
    double angle_max
  ) const {
    // 스캔 범위로 제한
    angle_min = std::max(angle_min, static_cast<double>(scan.angle_min));
    angle_max = std::min(angle_max, static_cast<double>(scan.angle_max));

    if (angle_max <= angle_min) {
      return std::numeric_limits<double>::infinity();
    }

    // 인덱스 계산
    const int idx_min = static_cast<int>(
      std::floor((angle_min - scan.angle_min) / scan.angle_increment)
    );
    const int idx_max = static_cast<int>(
      std::ceil((angle_max - scan.angle_min) / scan.angle_increment)
    );

    const int i_start = std::clamp(idx_min, 0, static_cast<int>(scan.ranges.size()) - 1);
    const int i_end = std::clamp(idx_max, 0, static_cast<int>(scan.ranges.size()) - 1);

    // 최소 거리 탐색
    double min_range = std::numeric_limits<double>::infinity();

    for (int i = i_start; i <= i_end; ++i) {
      const float range = scan.ranges[i];

      // 유효성 검사
      if (!std::isfinite(range)) continue;
      if (range < scan.range_min || range > scan.range_max) continue;

      min_range = std::min(min_range, static_cast<double>(range));
    }

    return min_range;
  }

  /**
   * @brief 회피 방향 결정
   *
   * 좌우 중 더 열린 공간 쪽으로 회전
   *
   * @param left_dist 좌측 최소 거리
   * @param right_dist 우측 최소 거리
   * @param yaw_magnitude 회전 강도
   * @return 회전 속도 (+: 반시계방향/좌회전, -: 시계방향/우회전)
   */
  double chooseAvoidanceYaw(
    double left_dist,
    double right_dist,
    double yaw_magnitude
  ) const {
    const bool left_valid = std::isfinite(left_dist);
    const bool right_valid = std::isfinite(right_dist);

    // 양쪽 모두 유효: 더 먼 쪽으로
    if (left_valid && right_valid) {
      return (left_dist > right_dist) ? +yaw_magnitude : -yaw_magnitude;
    }

    // 좌측만 유효: 좌회전
    if (left_valid) {
      return +yaw_magnitude;
    }

    // 우측만 유효: 우회전
    if (right_valid) {
      return -yaw_magnitude;
    }

    // 양쪽 모두 무효: 회전하지 않음
    return 0.0;
  }

  // =====================================================
  // 멤버 변수
  // =====================================================

  // ROS 인터페이스
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_cmd_;
  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr sub_scan_;
  rclcpp::TimerBase::SharedPtr timer_;

  // 상태
  bool got_scan_{false};
  sensor_msgs::msg::LaserScan::SharedPtr last_scan_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<SafetyOverrideNode>();

  try {
    rclcpp::spin(node);
  } catch (const std::exception& e) {
    RCLCPP_ERROR(node->get_logger(), "Exception in safety_override_node: %s", e.what());
  }

  rclcpp::shutdown();
  return 0;
}
