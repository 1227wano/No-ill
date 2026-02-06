#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/int32.hpp>
#include <std_msgs/msg/string.hpp>
#include <std_msgs/msg/bool.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>

#include <algorithm>
#include <cmath>
#include <string>
#include <limits>

class PersonOverrideNode : public rclcpp::Node {
public:
  PersonOverrideNode() : Node("person_override_node") {
    // ---- Topics ----
    declare_parameter<std::string>("person_x_topic", "/person_x");
    declare_parameter<std::string>("object_type_topic", "/object_type");
    declare_parameter<std::string>("cmd_topic", "/cmd_vel_person");

    // ---- Tracking tuning ----
    declare_parameter<int>("img_width", 224);

    // center 범위를 "비율"로 받는다 (img_width 바뀌어도 안전)
    declare_parameter<double>("center_min_ratio", 0.4); // 0~1
    declare_parameter<double>("center_max_ratio", 0.6); // 0~1

    declare_parameter<double>("base_speed", 0.3);
    declare_parameter<double>("kp", 1.2);
    declare_parameter<double>("max_yaw", 1.0);

    // 사람이 끊겼다고 판단하는 시간
    declare_parameter<double>("deadtime_sec", 1.0);

    // 좌우 방향이 반대면 토글로 해결 (TF/카메라 좌표계 바뀌어도 안전)
    declare_parameter<bool>("invert_yaw", false);

    declare_parameter<double>("publish_hz", 20.0);

    // tracking이 꺼질 때 0 cmd를 1회 쏠지(안전용, mux 정책 따라 선택)
    declare_parameter<bool>("publish_stop_on_disable", true);

    // ---- Fall accident ----
    declare_parameter<std::string>("fall_accident_topic", "/check_accident");
    declare_parameter<std::string>("arrived_callback_topic", "/fall_arrived");
    declare_parameter<std::string>("is_chatting_topic", "/is_chatting");

    declare_parameter<double>("fall_approach_speed", 0.15);
    declare_parameter<double>("fall_approach_time", 5.0);



    // ---- LiDAR 기반 도착 판정 ----
    declare_parameter<std::string>("scan_topic", "/scan");
    declare_parameter<double>("arrival_distance", 0.5);      // 50cm (낙상 모드)
    declare_parameter<double>("follow_stop_distance", 0.5);  // 50cm (일반 추적 모드)
    declare_parameter<double>("scan_angle_range", 20.0);     // 전방 ±25도

    const auto px_topic       = get_parameter("person_x_topic").as_string();
    const auto ot_topic       = get_parameter("object_type_topic").as_string();
    const auto cmd_topic      = get_parameter("cmd_topic").as_string();
    const auto fall_topic     = get_parameter("fall_accident_topic").as_string();
    const auto arrived_topic  = get_parameter("arrived_callback_topic").as_string();
    const auto chatting_topic = get_parameter("is_chatting_topic").as_string();
    const auto scan_topic     = get_parameter("scan_topic").as_string();

    pub_             = create_publisher<geometry_msgs::msg::Twist>(cmd_topic, 10);
    pub_fall_arrived_= create_publisher<std_msgs::msg::Bool>(arrived_topic, 10);
    pub_is_chatting_ = create_publisher<std_msgs::msg::Bool>(chatting_topic, 10);

    // LiDAR 구독
    sub_scan_ = create_subscription<sensor_msgs::msg::LaserScan>(
      scan_topic, rclcpp::SensorDataQoS(),
      [this](const sensor_msgs::msg::LaserScan::SharedPtr msg) {
        updateFrontDistance(msg);
      });

    sub_x_ = create_subscription<std_msgs::msg::Int32>(
      px_topic, 10,
      [this](const std_msgs::msg::Int32::SharedPtr msg) {
        last_x_     = msg->data;
        last_seen_  = now();
        seen_once_  = true;
      });

    sub_type_ = create_subscription<std_msgs::msg::String>(
      ot_topic, 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        const auto &t = msg->data;

        tracking_enabled_ = (t == "lying" || t == "others");
      });

    sub_fall_ = create_subscription<std_msgs::msg::Bool>(
      fall_topic, 10,
      [this](const std_msgs::msg::Bool::SharedPtr msg) {
        if (msg->data && !fall_detected_) {
          fall_detected_      = true;
          approach_started_   = false;
          arrived_            = false;
          RCLCPP_INFO(get_logger(), "Fall accident detected, starting emergency response");
        } else if (!msg->data && fall_detected_) {
          // check_accident=false 받으면 리셋
          fall_detected_      = false;
          approach_started_   = false;
          arrived_            = false;

          // is_chatting=false도 발행해서 chat_stop_gate 해제
          std_msgs::msg::Bool chatting_msg;
          chatting_msg.data = false;
          pub_is_chatting_->publish(chatting_msg);

          RCLCPP_INFO(get_logger(), "Fall accident cleared, resuming normal operation");
        }
      });

    // 시간 초기화 (clock 타입 불일치 방지)
    last_seen_ = now();
    approach_start_time_ = now();

    const double hz = get_parameter("publish_hz").as_double();
    timer_ = create_wall_timer(
      std::chrono::milliseconds(static_cast<int>(1000.0 / hz)),
      std::bind(&PersonOverrideNode::onTimer, this));

    RCLCPP_INFO(get_logger(), "person_override_node started");
    RCLCPP_INFO(get_logger(), "  person_x: %s", px_topic.c_str());
    RCLCPP_INFO(get_logger(), "  type    : %s", ot_topic.c_str());
    RCLCPP_INFO(get_logger(), "  cmd     : %s", cmd_topic.c_str());
    RCLCPP_INFO(get_logger(), "  fall    : %s", fall_topic.c_str());
    RCLCPP_INFO(get_logger(), "  arrived : %s", arrived_topic.c_str());
    RCLCPP_INFO(get_logger(), "  chatting: %s", chatting_topic.c_str());
    RCLCPP_INFO(get_logger(), "  scan    : %s (arrival_dist=%.2fm)",
                scan_topic.c_str(), get_parameter("arrival_distance").as_double());
  }

private:
  void publishStopOnce() {
    geometry_msgs::msg::Twist z;
    z.linear.x = 0.0;
    z.angular.z = 0.0;
    pub_->publish(z);
  }

  void updateFrontDistance(const sensor_msgs::msg::LaserScan::SharedPtr& scan) {
    const double angle_range_deg = get_parameter("scan_angle_range").as_double();
    const double angle_range_rad = angle_range_deg * M_PI / 180.0;

    double min_dist = std::numeric_limits<double>::infinity();

    for (size_t i = 0; i < scan->ranges.size(); ++i) {
      double angle = scan->angle_min + i * scan->angle_increment;

      // 전방 ±angle_range 범위만 체크
      if (std::abs(angle) <= angle_range_rad) {
        double r = scan->ranges[i];
        if (r >= scan->range_min && r <= scan->range_max && r < min_dist) {
          min_dist = r;
        }
      }
    }

    front_distance_ = min_dist;
  }

  void triggerArrival(const std::string& reason) {
    publishStopOnce();

    std_msgs::msg::Bool arrived_msg;
    arrived_msg.data = true;
    pub_fall_arrived_->publish(arrived_msg);

    // 응급 상황에서는 is_chatting 발행하지 않음
    // Emergency Response가 대화 흐름을 직접 제어함

    arrived_ = true;
    RCLCPP_INFO(get_logger(), "Arrived at fallen person (%s), triggering emergency response", reason.c_str());
  }

  void onTimer() {
    // tracking_enabled_ 변화 감지 (disable 순간 stop 1회 publish 옵션)
    const bool publish_stop_on_disable = get_parameter("publish_stop_on_disable").as_bool();
    if (publish_stop_on_disable && was_tracking_enabled_ && !tracking_enabled_ && !fall_detected_) {
      publishStopOnce();
    }
    was_tracking_enabled_ = tracking_enabled_;

    if (fall_detected_) {
      handleFallAccident();
      return;
    }

    const double deadtime = get_parameter("deadtime_sec").as_double();
    const double dt = (now() - last_seen_).seconds();
    const double follow_stop_dist = get_parameter("follow_stop_distance").as_double();

    // 추적 모드 정지 상태 처리
    if (follow_stopped_) {
      if (front_distance_ <= 1.0) {
        // 전방 1m 이내면 계속 멈춤 (쪼그려 앉아도 유지)
        publishStopOnce();
        return;
      } else {
        // 1m 이상 벌어지면 정지 상태 해제
        follow_stopped_ = false;
        RCLCPP_INFO(get_logger(), "Person moved away (>1m), resuming tracking");
      }
    }

    // 사람 본 적 있고 deadtime 이내면, tracking 끊겨도 정지 체크
    if (seen_once_ && dt <= deadtime && front_distance_ <= follow_stop_dist) {
      follow_stopped_ = true;
      publishStopOnce();
      return;
    }

    if (!tracking_enabled_) return;
    if (!seen_once_) return;

    if (dt > deadtime) {
      // deadtime 지나면 publish 중단 -> mux가 nav2로 복귀
      follow_stopped_ = false;  // 정지 상태도 리셋
      return;
    }

    const int img_width = get_parameter("img_width").as_int();

    const double center_min_ratio = get_parameter("center_min_ratio").as_double();
    const double center_max_ratio = get_parameter("center_max_ratio").as_double();

    const int center_min = static_cast<int>(std::round(img_width * center_min_ratio));
    const int center_max = static_cast<int>(std::round(img_width * center_max_ratio));

    const double base_speed = get_parameter("base_speed").as_double();
    const double kp = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();
    const bool invert_yaw = get_parameter("invert_yaw").as_bool();

    int x = std::clamp(last_x_, 0, img_width);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = base_speed;

    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      const double cx = img_width / 2.0;
      const double err = (static_cast<double>(x) - cx) / cx; // -1~+1 (왼쪽 -, 오른쪽 +)
      double yaw = kp * err; // 오른쪽(+)이면 yaw(+) -> CCW(좌회전)라서 보통 반대가 맞음
      // 기본적으로는 "오른쪽이면 우회전"이 되어야 하니 - 부호를 주는 게 흔함
      yaw = -yaw;
      if (invert_yaw) yaw = -yaw; // 토글
      cmd.angular.z = std::clamp(yaw, -max_yaw, +max_yaw);
    }

    pub_->publish(cmd);
  }

  void handleFallAccident() {
    if (arrived_) return;

    const int img_width = get_parameter("img_width").as_int();
    const double center_min_ratio = get_parameter("center_min_ratio").as_double();
    const double center_max_ratio = get_parameter("center_max_ratio").as_double();

    const int center_min = static_cast<int>(std::round(img_width * center_min_ratio));
    const int center_max = static_cast<int>(std::round(img_width * center_max_ratio));

    const double fall_speed = get_parameter("fall_approach_speed").as_double();
    const double fall_time  = get_parameter("fall_approach_time").as_double();

    const double kp      = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();
    const bool invert_yaw = get_parameter("invert_yaw").as_bool();

    geometry_msgs::msg::Twist cmd;

    // 낙상 감지됐으면 이미 30프레임 봤으므로 seen_once_는 항상 true

    // 3) 접근 시작 타임 스탬프 세팅
    if (!approach_started_) {
      approach_started_ = true;
      approach_start_time_ = now();
      RCLCPP_INFO(get_logger(), "Person found, starting approach");
    }

    const double elapsed = (now() - approach_start_time_).seconds();

    // 4) LiDAR 거리 기반 도착 판정 (우선)
    const double arrival_dist = get_parameter("arrival_distance").as_double();
    if (front_distance_ <= arrival_dist) {
      triggerArrival("LiDAR distance");
      return;
    }

    // 5) 시간 기반 도착 처리 (백업)
    if (elapsed >= fall_time) {
      triggerArrival("time-based fallback");
      return;
    }

    // 6) 추적 기반 접근
    int x = std::clamp(last_x_, 0, img_width);
    cmd.linear.x = fall_speed;

    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      const double cx = img_width / 2.0;
      const double err = (static_cast<double>(x) - cx) / cx;
      double yaw = kp * err;
      yaw = -yaw;
      if (invert_yaw) yaw = -yaw;
      cmd.angular.z = std::clamp(yaw, -max_yaw, +max_yaw);
    }

    pub_->publish(cmd);
  }

  // ROS
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_fall_arrived_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_is_chatting_;
  rclcpp::Subscription<std_msgs::msg::Int32>::SharedPtr sub_x_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_type_;
  rclcpp::Subscription<std_msgs::msg::Bool>::SharedPtr sub_fall_;
  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr sub_scan_;
  rclcpp::TimerBase::SharedPtr timer_;

  // State
  bool tracking_enabled_{false};
  bool was_tracking_enabled_{false};

  bool seen_once_{false};
  int last_x_{160};
  rclcpp::Time last_seen_;

  bool fall_detected_{false};
  bool approach_started_{false};
  bool arrived_{false};
  rclcpp::Time approach_start_time_;

  // 추적 모드 정지 상태
  bool follow_stopped_{false};

  // LiDAR
  double front_distance_{std::numeric_limits<double>::infinity()};
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PersonOverrideNode>());
  rclcpp::shutdown();
  return 0;
}

