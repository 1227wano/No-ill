#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

#include <cstdint>
#include <cmath>
#include <string>
#include <algorithm>

/* ===================== PCA9685 low-level ===================== */
class PCA9685 {
public:
  PCA9685(const std::string& i2c_dev, uint8_t addr)
  : i2c_dev_(i2c_dev), addr_(addr) {}

  void open_bus() {
    fd_ = ::open(i2c_dev_.c_str(), O_RDWR);
    if (fd_ < 0) throw std::runtime_error("open " + i2c_dev_ + " failed");
    if (ioctl(fd_, I2C_SLAVE, addr_) < 0) throw std::runtime_error("ioctl I2C_SLAVE failed");
  }

  void close_bus() {
    if (fd_ >= 0) ::close(fd_);
    fd_ = -1;
  }

  ~PCA9685() { close_bus(); }

  void set_freq_hz(int freq_hz) {
    // prescale = round(25MHz/(4096*freq) - 1)
    int prescale = static_cast<int>(25000000.0 / (4096.0 * freq_hz) - 1.0 + 0.5);
    prescale = std::clamp(prescale, 3, 255);

    write_reg(0x00, 0x10); // MODE1 sleep
    usleep(1000);

    write_reg(0x01, 0x04); // MODE2 OUTDRV=1 (totem pole)
    usleep(1000);

    write_reg(0xFE, static_cast<uint8_t>(prescale)); // PRESCALE
    usleep(1000);

    write_reg(0x00, 0x20); // wake + AI
    usleep(5000);

    write_reg(0x00, 0xA0); // restart + AI
    usleep(5000);
  }

  void set_pwm_12(int ch, uint16_t on, uint16_t off) {
    uint8_t reg = static_cast<uint8_t>(0x06 + 4 * ch);
    uint8_t buf[5];
    buf[0] = reg;
    buf[1] = on & 0xFF;
    buf[2] = (on >> 8) & 0x0F;
    buf[3] = off & 0xFF;
    buf[4] = (off >> 8) & 0x0F;
    if (::write(fd_, buf, 5) != 5) throw std::runtime_error("set_pwm_12 write failed");
  }

  // FULL ON/OFF (bit4)
  void full_on(int ch) {
    uint8_t reg = static_cast<uint8_t>(0x06 + 4 * ch);
    uint8_t buf[5] = { reg, 0x00, 0x10, 0x00, 0x00 };
    if (::write(fd_, buf, 5) != 5) throw std::runtime_error("full_on write failed");
  }
  void full_off(int ch) {
    uint8_t reg = static_cast<uint8_t>(0x06 + 4 * ch);
    uint8_t buf[5] = { reg, 0x00, 0x00, 0x00, 0x10 };
    if (::write(fd_, buf, 5) != 5) throw std::runtime_error("full_off write failed");
  }

private:
  void write_reg(uint8_t reg, uint8_t val) {
    uint8_t buf[2] = { reg, val };
    if (::write(fd_, buf, 2) != 2) throw std::runtime_error("write_reg failed");
  }

  std::string i2c_dev_;
  uint8_t addr_;
  int fd_{-1};
};

/* ===================== Motor HAT mapping (your python) ===================== */
// python:
// pwm.channels[channel+5] = throttle PWM
// pwm.channels[channel+4] , pwm.channels[channel+3] = direction
// throttle < 0 : (ch+4=0, ch+3=1)
// throttle > 0 : (ch+4=1, ch+3=0)
class PWMThrottleHat {
public:
  PWMThrottleHat(PCA9685& pca, int base_channel)
  : pca_(pca), base_(base_channel) {}

  void set_throttle(double throttle) {
    throttle = std::clamp(throttle, -1.0, 1.0);
    int pwm_ch = base_ + 5;
    int in1_ch = base_ + 4;
    int in2_ch = base_ + 3;

    const int duty = static_cast<int>(std::lround(4095.0 * std::fabs(throttle))); // 0..4095

    if (throttle < 0.0) {
      // "forward" in your python comment
      pca_.set_pwm_12(pwm_ch, 0, duty);
      pca_.full_off(in1_ch);
      pca_.full_on(in2_ch);
    } else if (throttle > 0.0) {
      // "backward"
      pca_.set_pwm_12(pwm_ch, 0, duty);
      pca_.full_on(in1_ch);
      pca_.full_off(in2_ch);
    } else {
      pca_.set_pwm_12(pwm_ch, 0, 0);
      pca_.full_off(in1_ch);
      pca_.full_off(in2_ch);
    }
  }

private:
  PCA9685& pca_;
  int base_;
};

/* ===================== Servo helper ===================== */
class ServoSteer {
public:
  ServoSteer(PCA9685& pca, int ch, int center_deg, int min_deg, int max_deg,
             int us_min=600, int us_max=2400)
  : pca_(pca), ch_(ch),
    center_(center_deg), min_(min_deg), max_(max_deg),
    us_min_(us_min), us_max_(us_max) {}

  void set_angle_deg(int deg) {
    deg = std::clamp(deg, min_, max_);
    // angle 0..180 -> us_min..us_max (simple map)
    // 네 차는 center=90을 기준으로 쓸 거라 center 파라미터 제공
    const double us = us_min_ + (us_max_ - us_min_) * (deg / 180.0);
    set_pulse_us(us);
  }

  void set_center() { set_angle_deg(center_); }

  void set_from_angular_z(double az, double az_max) {
    // az in [-az_max, az_max] -> angle in [min,max], centered at center_
    if (az_max <= 1e-6) { set_center(); return; }
    double x = std::clamp(az / az_max, -1.0, 1.0);

    // 중심 기준 좌/우로 선형 매핑
    int left_span  = center_ - min_;
    int right_span = max_ - center_;
    int deg = center_;
    if (x < 0) deg = center_ + static_cast<int>(std::lround(x * left_span));   // x 음수면 왼쪽
    else       deg = center_ + static_cast<int>(std::lround(x * right_span));  // x 양수면 오른쪽
    set_angle_deg(deg);
  }

private:
  void set_pulse_us(double us) {
    // PCA9685: off_count = pulse_us / period_us * 4096
    // 여기서는 pca 주파수에 의존. 서보 PCA는 60Hz(=16666us) 또는 50Hz(=20000us)
    // 우리는 "절대 us"가 아니라 현재 주파수 기준으로 계산.
    // period_us는 freq로부터 계산해야 하는데, 여기선 60Hz 사용을 권장(너 파이썬도 60Hz)
    // => period_us = 1e6 / 60 = 16666.666...
    const double period_us = 1e6 / 60.0; // 서보 PCA는 60Hz로 맞출 거라서 고정
    uint16_t off = static_cast<uint16_t>(std::clamp<int>(
      static_cast<int>(std::lround((us / period_us) * 4096.0)),
      0, 4095
    ));
    pca_.set_pwm_12(ch_, 0, off);
  }

  PCA9685& pca_;
  int ch_;
  int center_, min_, max_;
  int us_min_, us_max_;
};

/* ===================== ROS2 Node ===================== */
class PcaDriveNode : public rclcpp::Node {
public:
  PcaDriveNode() : Node("pca_drive_node") {
    // ---- params
    i2c_dev_      = declare_parameter<std::string>("i2c_dev", "/dev/i2c-7");

    addr_servo_   = declare_parameter<int>("addr_servo", 0x60);
    servo_ch_     = declare_parameter<int>("servo_channel", 0);
    servo_center_ = declare_parameter<int>("servo_center_deg", 90);
    servo_min_    = declare_parameter<int>("servo_min_deg", 30);
    servo_max_    = declare_parameter<int>("servo_max_deg", 150);

    addr_motor_   = declare_parameter<int>("addr_motor", 0x40);
    motor_base_   = declare_parameter<int>("motor_base_channel", 0); // python channel=0 -> 3/4/5

    servo_freq_   = declare_parameter<int>("servo_freq_hz", 60);
    motor_freq_   = declare_parameter<int>("motor_freq_hz", 60); // 너 파이썬이 60Hz라 동일하게

    max_lin_      = declare_parameter<double>("max_linear", 0.5);  // cmd_vel linear.x 이 값이면 full throttle
    max_ang_      = declare_parameter<double>("max_angular", 1.0); // cmd_vel angular.z 이 값이면 최대 조향

    deadband_     = declare_parameter<double>("deadband", 0.03);   // 작은 떨림 제거
    accel_rate_   = declare_parameter<double>("accel_rate", 1.5);  // throttle 1.0까지 올라가는데 ~0.66s 정도
    timeout_sec_  = declare_parameter<double>("cmd_timeout", 0.3);

    // ---- open PCA devices
    pca_servo_ = std::make_unique<PCA9685>(i2c_dev_, static_cast<uint8_t>(addr_servo_));
    pca_motor_ = std::make_unique<PCA9685>(i2c_dev_, static_cast<uint8_t>(addr_motor_));

    pca_servo_->open_bus();
    pca_motor_->open_bus();

    pca_servo_->set_freq_hz(servo_freq_);
    pca_motor_->set_freq_hz(motor_freq_);

    servo_ = std::make_unique<ServoSteer>(*pca_servo_, servo_ch_, servo_center_, servo_min_, servo_max_);
    motor_ = std::make_unique<PWMThrottleHat>(*pca_motor_, motor_base_);

    // safe init
    servo_->set_center();
    motor_->set_throttle(0.0);

    sub_ = create_subscription<geometry_msgs::msg::Twist>(
      "cmd_vel", 10,
      [this](const geometry_msgs::msg::Twist::SharedPtr msg){
        last_cmd_time_ = now();
        target_lin_ = msg->linear.x;
        target_ang_ = msg->angular.z;
      }
    );

    // control loop 50Hz
    timer_ = create_wall_timer(
      std::chrono::milliseconds(20),
      std::bind(&PcaDriveNode::tick, this)
    );

    RCLCPP_INFO(get_logger(), "pca_drive_node started (servo 0x%02x, motor 0x%02x)", addr_servo_, addr_motor_);
  }

  ~PcaDriveNode() override {
    try {
      if (motor_) motor_->set_throttle(0.0);
      if (servo_) servo_->set_center();
    } catch (...) {}
  }

private:
  void tick() {
    const auto t = now();
    const double dt = 0.02;

    // timeout -> stop
    if ((t - last_cmd_time_).seconds() > timeout_sec_) {
      target_lin_ = 0.0;
      target_ang_ = 0.0;
    }

    // map linear.x -> throttle [-1..1]
    double throttle = 0.0;
    if (std::fabs(max_lin_) > 1e-6) throttle = std::clamp(target_lin_ / max_lin_, -1.0, 1.0);

    // deadband
    if (std::fabs(throttle) < deadband_) throttle = 0.0;

    // ramp (accel limit)
    const double max_step = accel_rate_ * dt; // throttle units per tick
    double diff = throttle - cur_throttle_;
    diff = std::clamp(diff, -max_step, max_step);
    cur_throttle_ += diff;

    // apply motor + servo
    motor_->set_throttle(cur_throttle_);
    servo_->set_from_angular_z(target_ang_, max_ang_);
  }

  // params/state
  std::string i2c_dev_;
  int addr_servo_, servo_ch_, servo_center_, servo_min_, servo_max_;
  int addr_motor_, motor_base_;
  int servo_freq_, motor_freq_;
  double max_lin_, max_ang_, deadband_, accel_rate_, timeout_sec_;

  double target_lin_{0.0}, target_ang_{0.0};
  double cur_throttle_{0.0};
  rclcpp::Time last_cmd_time_{0,0,RCL_ROS_TIME};

  std::unique_ptr<PCA9685> pca_servo_;
  std::unique_ptr<PCA9685> pca_motor_;
  std::unique_ptr<ServoSteer> servo_;
  std::unique_ptr<PWMThrottleHat> motor_;

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr sub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char** argv){
  rclcpp::init(argc, argv);
  try {
    auto node = std::make_shared<PcaDriveNode>();
    rclcpp::spin(node);
  } catch (const std::exception& e) {
    fprintf(stderr, "Fatal: %s\n", e.what());
  }
  rclcpp::shutdown();
  return 0;
}

