#include <chrono>
#include <memory>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/bool.hpp"
#include "geometry_msgs/msg/twist.hpp"

using namespace std::chrono_literals;

class ChatStopGateNode : public rclcpp::Node {
public:
  ChatStopGateNode() : Node("chat_stop_gate_node") {
    // params
    this->declare_parameter<std::string>("is_chatting_topic", "/is_chatting");
    this->declare_parameter<std::string>("cmd_out_topic", "/cmd_vel_is_chatting");
    this->declare_parameter<double>("publish_hz", 10.0);

    is_chatting_topic_ = this->get_parameter("is_chatting_topic").as_string();
    cmd_out_topic_ = this->get_parameter("cmd_out_topic").as_string();
    publish_hz_ = this->get_parameter("publish_hz").as_double();
    if (publish_hz_ <= 0.0) publish_hz_ = 10.0;

    pub_ = this->create_publisher<geometry_msgs::msg::Twist>(cmd_out_topic_, 10);

    sub_ = this->create_subscription<std_msgs::msg::Bool>(
      is_chatting_topic_, rclcpp::QoS(10).reliable(),
      [this](const std_msgs::msg::Bool::SharedPtr msg) {
        chatting_ = msg->data;
        RCLCPP_INFO(this->get_logger(), "is_chatting=%s", chatting_ ? "true" : "false");
      });

    auto period = std::chrono::duration<double>(1.0 / publish_hz_);
    timer_ = this->create_wall_timer(
      std::chrono::duration_cast<std::chrono::nanoseconds>(period),
      [this]() {
        if (!chatting_) return;
        geometry_msgs::msg::Twist z;
        z.linear.x = 0.0;
        z.linear.y = 0.0;
        z.linear.z = 0.0;
        z.angular.x = 0.0;
        z.angular.y = 0.0;
        z.angular.z = 0.0;
        pub_->publish(z);
      });

    RCLCPP_INFO(this->get_logger(),
      "ChatStopGate ready. sub=%s pub=%s hz=%.1f",
      is_chatting_topic_.c_str(), cmd_out_topic_.c_str(), publish_hz_);
  }

private:
  std::string is_chatting_topic_;
  std::string cmd_out_topic_;
  double publish_hz_;

  bool chatting_{false};

  rclcpp::Subscription<std_msgs::msg::Bool>::SharedPtr sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char ** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ChatStopGateNode>());
  rclcpp::shutdown();
  return 0;
}

