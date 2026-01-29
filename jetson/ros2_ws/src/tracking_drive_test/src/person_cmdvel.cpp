#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/int32.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <algorithm>
#include <cmath>

class personCmdVel : public rclcpp::Node {
public:
  personCmdVel() : Node("person_cmdvel") {
    img_w_       = declare_parameter<int>("img_w", 320);
    base_v_      = declare_parameter<double>("base_v", 0.0);
    max_yaw_     = declare_parameter<double>("max_yaw", 0.3);
    deadband_px_ = declare_parameter<double>("deadband_px", 20.0);
    alpha_       = declare_parameter<double>("alpha", 0.2);
    invert_      = declare_parameter<bool>("invert", false);

    publish_hz_  = declare_parameter<double>("publish_hz", 20.0);
    x_timeout_   = declare_parameter<double>("x_timeout", 0.5); // person_x 끊기면 정지

    sub_ = create_subscription<std_msgs::msg::Int32>(
      "/person_x", 10,
      std::bind(&personCmdVel::on_x, this, std::placeholders::_1));

    pub_ = create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);

    auto period_ms = std::chrono::milliseconds((int)std::lround(1000.0 / publish_hz_));
    timer_ = create_wall_timer(period_ms, std::bind(&personCmdVel::tick, this));

    last_x_time_ = now();
    RCLCPP_INFO(get_logger(), "publishing /cmd_vel at %.1f Hz", publish_hz_);
  }

private:
  void on_x(const std_msgs::msg::Int32::SharedPtr msg) {
    last_x_time_ = now();
    last_x_ = std::clamp(msg->data, 0, img_w_);
  }

  void tick() {
    // person_x 끊기면 안전정지 (pca_drive timeout보다 짧/길게 조절 가능)
    bool x_ok = (now() - last_x_time_).seconds() <= x_timeout_;

    double yaw_cmd = 0.0;
    double v_cmd   = 0.0;

    if (x_ok) {
      const double center = img_w_ * 0.5; // 80
      double err = (double)last_x_ - center;

      if (std::fabs(err) < deadband_px_) err = 0.0;

      double norm = std::clamp(err / center, -1.0, 1.0);
      double yaw = norm * max_yaw_;
      if (invert_) yaw *= -1.0;

      // 필터
      yaw_f_ = (1.0 - alpha_) * yaw_f_ + alpha_ * yaw;

      yaw_cmd = yaw_f_;
      v_cmd = base_v_;
    } else {
      yaw_f_ = 0.0; // 끊기면 필터도 리셋
      yaw_cmd = 0.0;
      v_cmd = 0.0;
    }

    geometry_msgs::msg::Twist t;
    t.linear.x = v_cmd;
    t.angular.z = yaw_cmd;
    pub_->publish(t);

    RCLCPP_INFO_THROTTLE(get_logger(), *get_clock(), 500,
      "x=%d x_ok=%d cmd: v=%.2f yaw=%.2f", last_x_, x_ok ? 1 : 0, v_cmd, yaw_cmd);
  }

  // ROS
  rclcpp::Subscription<std_msgs::msg::Int32>::SharedPtr sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;

  // params
  int img_w_;
  double base_v_, max_yaw_, deadband_px_, alpha_;
  bool invert_;
  double publish_hz_, x_timeout_;

  // state
  int last_x_{80};
  double yaw_f_{0.0};
  rclcpp::Time last_x_time_{0,0,RCL_ROS_TIME};
};
int main(int argc, char **argv){
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<personCmdVel>());
  rclcpp::shutdown();
  return 0;
}

