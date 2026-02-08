#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>

#include <termios.h>
#include <unistd.h>
#include <sys/select.h>
#include <cmath>
#include <algorithm>

class KeyboardLatchNode : public rclcpp::Node {
public:
  KeyboardLatchNode() : Node("keyboard_latch_node") {
    // params
    publish_hz_ = declare_parameter<double>("publish_hz", 20.0);
    speed_step_ = declare_parameter<double>("speed_step", 0.05);
    steer_step_ = declare_parameter<double>("steer_step", 0.10);
    speed_max_  = declare_parameter<double>("speed_max", 0.6);
    steer_max_  = declare_parameter<double>("steer_max", 1.5);

    pub_ = create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);

    // terminal raw mode
    tcgetattr(STDIN_FILENO, &old_tio_);
    new_tio_ = old_tio_;
    new_tio_.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &new_tio_);

    auto period = std::chrono::duration<double>(1.0 / publish_hz_);
    timer_ = create_wall_timer(
      std::chrono::duration_cast<std::chrono::milliseconds>(period),
      std::bind(&KeyboardLatchNode::tick, this)
    );

    RCLCPP_INFO(get_logger(),
      "KeyboardLatch started. Keys: w/s speed +/- , a/d steer -/+ , SPACE=stop, Ctrl-C quit");
  }

  ~KeyboardLatchNode() override {
    tcsetattr(STDIN_FILENO, TCSANOW, &old_tio_);
  }

private:
  void tick(){
    // read all available keys this cycle
    while (true){
      int c = read_key_nonblock();
      if (c < 0) break;

      switch (c){
        case 'w': speed_ += speed_step_; break;
        case 's': speed_ -= speed_step_; break;
        case 'a': steer_ -= steer_step_; break;
        case 'd': steer_ += steer_step_; break;
        case ' ': speed_ = 0.0; steer_ = 0.0; break; // emergency stop
        default: break;
      }

      speed_ = std::clamp(speed_, -speed_max_, speed_max_);
      steer_ = std::clamp(steer_, -steer_max_, steer_max_);

      RCLCPP_INFO(get_logger(), "speed=%.2f steer=%.2f", speed_, steer_);
    }

    geometry_msgs::msg::Twist msg;
    msg.linear.x  = speed_;
    msg.angular.z = steer_;
    pub_->publish(msg);
  }

  int read_key_nonblock(){
    fd_set set;
    struct timeval tv {0, 0};
    FD_ZERO(&set);
    FD_SET(STDIN_FILENO, &set);
    int rv = select(STDIN_FILENO + 1, &set, nullptr, nullptr, &tv);
    if (rv > 0){
      char c;
      if (read(STDIN_FILENO, &c, 1) == 1) return c;
    }
    return -1;
  }

  // params/state
  double publish_hz_{20.0};
  double speed_step_{0.05}, steer_step_{0.10};
  double speed_max_{0.6}, steer_max_{1.5};
  double speed_{0.0}, steer_{0.0};

  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;

  struct termios old_tio_{}, new_tio_{};
};

int main(int argc, char** argv){
  rclcpp::init(argc, argv);
  auto node = std::make_shared<KeyboardLatchNode>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}

