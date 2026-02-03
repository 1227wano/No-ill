#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <algorithm>
#include <cmath>
#include <limits>
#include <string>

class SafetyOverrideNode : public rclcpp::Node {
public:
  SafetyOverrideNode() : Node("safety_override_node") {
    declare_parameter<std::string>("scan_topic", "/scan");
    declare_parameter<std::string>("cmd_topic", "/cmd_vel_safety");

    declare_parameter<double>("slow_dist", 0.30);     // 50cm
    declare_parameter<double>("reverse_dist", 0.25);  // 20cm

    declare_parameter<double>("min_fwd", 0.25);       // 20~50cm 구간 최소 전진속도(정지 방지용)
    declare_parameter<double>("rev_speed", -0.10);    // 후진 속도

    declare_parameter<double>("max_yaw", 1.0);
    declare_parameter<double>("yaw_slow", 1.0);       // 20~50cm 회피 yaw 기본
    declare_parameter<double>("yaw_reverse", 0.6);    // 20cm 이내 후진 yaw 기본

    declare_parameter<double>("sector_front_deg", 15.0);
    declare_parameter<double>("sector_side_min_deg", 10.0);
    declare_parameter<double>("sector_side_max_deg", 200.0);

    declare_parameter<double>("publish_hz", 20.0);

    const auto scan_topic = get_parameter("scan_topic").as_string();
    const auto cmd_topic  = get_parameter("cmd_topic").as_string();

    pub_ = create_publisher<geometry_msgs::msg::Twist>(cmd_topic, 10);

    sub_ = create_subscription<sensor_msgs::msg::LaserScan>(
      scan_topic, rclcpp::SensorDataQoS(),
      [this](const sensor_msgs::msg::LaserScan::SharedPtr msg) {
        last_scan_ = msg;
        got_scan_ = true;
      });

    const double hz = get_parameter("publish_hz").as_double();
    timer_ = create_wall_timer(
      std::chrono::milliseconds((int)(1000.0 / hz)),
      std::bind(&SafetyOverrideNode::onTimer, this));

    RCLCPP_INFO(get_logger(), "safety_override_node started");
    RCLCPP_INFO(get_logger(), "  scan: %s", scan_topic.c_str());
    RCLCPP_INFO(get_logger(), "  cmd : %s", cmd_topic.c_str());
  }

private:
  static double deg2rad(double d) { return d * M_PI / 180.0; }

  double minRangeInSector(const sensor_msgs::msg::LaserScan& scan, double ang_min, double ang_max) {
    ang_min = std::max(ang_min, (double)scan.angle_min);
    ang_max = std::min(ang_max, (double)scan.angle_max);
    if (ang_max <= ang_min) return std::numeric_limits<double>::infinity();

    int i0 = (int)std::floor((ang_min - scan.angle_min) / scan.angle_increment);
    int i1 = (int)std::ceil ((ang_max - scan.angle_min) / scan.angle_increment);
    i0 = std::clamp(i0, 0, (int)scan.ranges.size() - 1);
    i1 = std::clamp(i1, 0, (int)scan.ranges.size() - 1);
    if (i1 < i0) std::swap(i0, i1);

    double best = std::numeric_limits<double>::infinity();
    for (int i = i0; i <= i1; ++i) {
      const float r = scan.ranges[i];
      if (!std::isfinite(r)) continue;
      if (r < scan.range_min || r > scan.range_max) continue;
      best = std::min(best, (double)r);
    }
    return best;
  }

  // 좌/우 중 더 먼 쪽 방향으로 yaw 결정(+는 좌, -는 우) (라이다 기준 +각이 좌라고 가정)
  double chooseAvoidYaw(double left, double right, double yaw_mag) {
    if (std::isfinite(left) && std::isfinite(right)) {
      return (left > right) ? +yaw_mag : -yaw_mag;
    } else if (std::isfinite(left)) {
      return +yaw_mag;
    } else if (std::isfinite(right)) {
      return -yaw_mag;
    }
    return 0.0;
  }

  void onTimer() {
    if (!got_scan_ || !last_scan_) return;
    const auto& scan = *last_scan_;

    const double slow_dist    = get_parameter("slow_dist").as_double();
    const double reverse_dist = get_parameter("reverse_dist").as_double();
    const double min_fwd      = get_parameter("min_fwd").as_double();
    const double rev_speed    = get_parameter("rev_speed").as_double();

    const double max_yaw      = get_parameter("max_yaw").as_double();
    const double yaw_slow     = get_parameter("yaw_slow").as_double();
    const double yaw_reverse  = get_parameter("yaw_reverse").as_double();

    const double front_deg      = get_parameter("sector_front_deg").as_double();
    const double side_min_deg   = get_parameter("sector_side_min_deg").as_double();
    const double side_max_deg   = get_parameter("sector_side_max_deg").as_double();

    const double front = minRangeInSector(scan, deg2rad(-front_deg), deg2rad(+front_deg));
    const double left  = minRangeInSector(scan, deg2rad(+side_min_deg), deg2rad(+side_max_deg));
    const double right = minRangeInSector(scan, deg2rad(-side_max_deg), deg2rad(-side_min_deg));

    // front가 무한대거나, 50cm보다 멀면 안전介入 안 함 (publish 안 함)
    if (!std::isfinite(front) || front > slow_dist) return;

    geometry_msgs::msg::Twist cmd;

    // 30cm 이내: 후진 + 반대방향 회피 조향 (다시 전진 시 열린 공간으로 향하도록)
    if (front <= reverse_dist) {
      cmd.linear.x  = rev_speed;
      // 반대 방향으로 틀어야 다시 전진할 때 피할 각이 생김
      cmd.angular.z = std::clamp(-chooseAvoidYaw(left, right, yaw_reverse), -max_yaw, +max_yaw);
      pub_->publish(cmd);
      return;
    }

    // 20~50cm: 감속 + 회피 조향 (가까울수록 더 강하게)
    // t=0(20cm) ~ t=1(50cm)
    double t = (front - reverse_dist) / (slow_dist - reverse_dist);
    t = std::clamp(t, 0.0, 1.0);

    // 속도: 50cm 근처에서도 조금은 움직이게 min_fwd 유지
    cmd.linear.x = min_fwd * t;

    // yaw: 가까울수록 강하게 (1-t)
    double yaw = chooseAvoidYaw(left, right, yaw_slow);
    yaw *= (1.0 - t);
    cmd.angular.z = std::clamp(yaw, -max_yaw, +max_yaw);

    pub_->publish(cmd);
  }

  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr sub_;
  rclcpp::TimerBase::SharedPtr timer_;

  bool got_scan_{false};
  sensor_msgs::msg::LaserScan::SharedPtr last_scan_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<SafetyOverrideNode>());
  rclcpp::shutdown();
  return 0;
}

