#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/int32.hpp>
#include <std_msgs/msg/string.hpp>
#include <std_msgs/msg/bool.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <algorithm>
#include <cmath>
#include <string>

class PersonOverrideNode : public rclcpp::Node {
public:
  PersonOverrideNode() : Node("person_override_node") {
    declare_parameter<std::string>("person_x_topic", "/person_x");
    declare_parameter<std::string>("object_type_topic", "/object_type");
    declare_parameter<std::string>("cmd_topic", "/cmd_vel_person");

    declare_parameter<int>("img_width", 160);
    declare_parameter<int>("center_min", 70);
    declare_parameter<int>("center_max", 90);

    declare_parameter<double>("base_speed", 0.15);
    declare_parameter<double>("kp", 1.2);
    declare_parameter<double>("max_yaw", 1.0);
    declare_parameter<double>("deadtime_sec", 3.0);
    declare_parameter<double>("publish_hz", 20.0);

    declare_parameter<std::string>("fall_accident_topic", "/check_accident");
    declare_parameter<std::string>("arrived_callback_topic", "/fall_arrived");
    declare_parameter<std::string>("is_chatting_topic", "/is_chatting");
    declare_parameter<double>("fall_approach_speed", 0.1);
    declare_parameter<double>("fall_approach_time", 5.0);

    const auto px_topic = get_parameter("person_x_topic").as_string();
    const auto ot_topic = get_parameter("object_type_topic").as_string();
    const auto cmd_topic = get_parameter("cmd_topic").as_string();
    const auto fall_topic = get_parameter("fall_accident_topic").as_string();
    const auto arrived_topic = get_parameter("arrived_callback_topic").as_string();
    const auto chatting_topic = get_parameter("is_chatting_topic").as_string();

    pub_ = create_publisher<geometry_msgs::msg::Twist>(cmd_topic, 10);
    pub_fall_arrived_ = create_publisher<std_msgs::msg::Bool>(arrived_topic, 10);
    pub_is_chatting_ = create_publisher<std_msgs::msg::Bool>(chatting_topic, 10);

    sub_x_ = create_subscription<std_msgs::msg::Int32>(
      px_topic, 10,
      [this](const std_msgs::msg::Int32::SharedPtr msg) {
        last_x_ = msg->data;
        last_seen_ = now();
        seen_once_ = true;
      });

    sub_type_ = create_subscription<std_msgs::msg::String>(
      ot_topic, 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        tracking_enabled_ = (msg->data == "person");
      });

    sub_fall_ = create_subscription<std_msgs::msg::Bool>(
      fall_topic, 10,
      [this](const std_msgs::msg::Bool::SharedPtr msg) {
        if (msg->data && !fall_detected_) {
          fall_detected_ = true;
          approach_started_ = false;
          arrived_ = false;
          RCLCPP_INFO(get_logger(), "Fall accident detected, starting emergency response");
        }
      });

    const double hz = get_parameter("publish_hz").as_double();
    timer_ = create_wall_timer(
      std::chrono::milliseconds((int)(1000.0 / hz)),
      std::bind(&PersonOverrideNode::onTimer, this));

    RCLCPP_INFO(get_logger(), "person_override_node started");
    RCLCPP_INFO(get_logger(), "  person_x: %s", px_topic.c_str());
    RCLCPP_INFO(get_logger(), "  type    : %s", ot_topic.c_str());
    RCLCPP_INFO(get_logger(), "  cmd     : %s", cmd_topic.c_str());
    RCLCPP_INFO(get_logger(), "  fall    : %s", fall_topic.c_str());
    RCLCPP_INFO(get_logger(), "  arrived : %s", arrived_topic.c_str());
    RCLCPP_INFO(get_logger(), "  chatting: %s", chatting_topic.c_str());
  }

private:
  void onTimer() {
    if (fall_detected_) {
      handleFallAccident();
      return;
    }

    if (!tracking_enabled_) return;
    if (!seen_once_) return;

    const double deadtime = get_parameter("deadtime_sec").as_double();
    const double dt = (now() - last_seen_).seconds();
    if (dt > deadtime) {
      // deadtime 지나면 publish 중단 -> mux가 nav2로 복귀
      return;
    }

    const int img_width = get_parameter("img_width").as_int();
    const int center_min = get_parameter("center_min").as_int();
    const int center_max = get_parameter("center_max").as_int();

    const double base_speed = get_parameter("base_speed").as_double();
    const double kp = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();

    int x = std::clamp(last_x_, 0, img_width);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = base_speed;

    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      const double cx = img_width / 2.0;
      double err = (static_cast<double>(x) - cx) / cx; // -1~+1
      double yaw = -kp * err;  // 방향 반대면 -만 제거
      cmd.angular.z = std::clamp(yaw, -max_yaw, +max_yaw);
    }

    pub_->publish(cmd);
  }

  void handleFallAccident() {
    if (arrived_) {
      return;
    }

    const int img_width = get_parameter("img_width").as_int();
    const int center_min = get_parameter("center_min").as_int();
    const int center_max = get_parameter("center_max").as_int();
    const double fall_speed = get_parameter("fall_approach_speed").as_double();
    const double fall_time = get_parameter("fall_approach_time").as_double();
    const double kp = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();

    geometry_msgs::msg::Twist cmd;

    if (!seen_once_) {
      cmd.linear.x = 0.0;
      cmd.angular.z = 0.5;
      pub_->publish(cmd);
      RCLCPP_INFO_THROTTLE(get_logger(), *get_clock(), 2000, "Searching for fallen person...");
      return;
    }

    if (!approach_started_) {
      approach_started_ = true;
      approach_start_time_ = now();
      RCLCPP_INFO(get_logger(), "Person found, starting approach");
    }

    const double elapsed = (now() - approach_start_time_).seconds();

    if (elapsed >= fall_time) {
      cmd.linear.x = 0.0;
      cmd.angular.z = 0.0;
      pub_->publish(cmd);

      std_msgs::msg::Bool arrived_msg;
      arrived_msg.data = true;
      pub_fall_arrived_->publish(arrived_msg);

      std_msgs::msg::Bool chatting_msg;
      chatting_msg.data = true;
      pub_is_chatting_->publish(chatting_msg);

      arrived_ = true;
      RCLCPP_INFO(get_logger(), "Arrived at fallen person, triggering conversation mode");
      return;
    }

    int x = std::clamp(last_x_, 0, img_width);
    cmd.linear.x = fall_speed;

    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      const double cx = img_width / 2.0;
      double err = (static_cast<double>(x) - cx) / cx;
      double yaw = -kp * err;
      cmd.angular.z = std::clamp(yaw, -max_yaw, +max_yaw);
    }

    pub_->publish(cmd);
  }

  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_fall_arrived_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_is_chatting_;
  rclcpp::Subscription<std_msgs::msg::Int32>::SharedPtr sub_x_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_type_;
  rclcpp::Subscription<std_msgs::msg::Bool>::SharedPtr sub_fall_;
  rclcpp::TimerBase::SharedPtr timer_;

  bool tracking_enabled_{false};
  bool seen_once_{false};
  int last_x_{160};
  rclcpp::Time last_seen_{0,0,RCL_ROS_TIME};

  bool fall_detected_{false};
  bool approach_started_{false};
  bool arrived_{false};
  rclcpp::Time approach_start_time_{0,0,RCL_ROS_TIME};
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PersonOverrideNode>());
  rclcpp::shutdown();
  return 0;
}

