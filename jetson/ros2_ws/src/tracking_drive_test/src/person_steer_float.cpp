#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/int32.hpp>
#include <std_msgs/msg/float32.hpp>
#include <algorithm>
#include <cmath>

class personSteerFloat : public rclcpp::Node {
public:
  personSteerFloat() : Node("person_steer_float") {
    // Params
    img_w_ = declare_parameter<int>("img_w", 320);
    max_steer_ = declare_parameter<double>("max_steer", 1.0);
    deadband_px_ = declare_parameter<double>("deadband_px", 6.0);
    alpha_ = declare_parameter<double>("alpha", 0.25); // low-pass
    invert_ = declare_parameter<bool>("invert", false);

    sub_ = create_subscription<std_msgs::msg::Int32>(
      "person_x", 10, std::bind(&personSteerFloat::cb, this, std::placeholders::_1));

    pub_ = create_publisher<std_msgs::msg::Float32>("steer_cmd", 10);

    RCLCPP_INFO(get_logger(),
      "img_w=%d max_steer=%.2f deadband=%.1f alpha=%.2f invert=%s",
      img_w_, max_steer_, deadband_px_, alpha_, invert_ ? "true":"false");
  }

private:
  void cb(const std_msgs::msg::Int32::SharedPtr msg) {
    const double center = img_w_ * 0.5;   // 80
    double x = std::clamp<double>(msg->data, 0.0, (double)img_w_);
    double err = center- x;              // 왼(-) 오른(+)

    if (std::fabs(err) < deadband_px_) err = 0.0;

    double norm = err / center;           // [-1,1]
    norm = std::clamp(norm, -1.0, 1.0);

    double steer = norm * max_steer_;
    if (invert_) steer *= -1.0;

    // low-pass filter
    steer_f_ = (1.0 - alpha_) * steer_f_ + alpha_ * steer;

    std_msgs::msg::Float32 out;
    out.data = (float)steer_f_;
    pub_->publish(out);

    RCLCPP_INFO_THROTTLE(get_logger(), *get_clock(), 200,
      "person_x=%d err=%.1f norm=%.2f steer=%.2f filt=%.2f",
      msg->data, err, norm, steer, steer_f_);
  }

  rclcpp::Subscription<std_msgs::msg::Int32>::SharedPtr sub_;
  rclcpp::Publisher<std_msgs::msg::Float32>::SharedPtr pub_;

  int img_w_;
  double max_steer_, deadband_px_, alpha_;
  bool invert_;
  double steer_f_ = 0.0;
};

int main(int argc, char **argv){
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<personSteerFloat>());
  rclcpp::shutdown();
  return 0;
}

