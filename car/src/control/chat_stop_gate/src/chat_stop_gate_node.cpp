/**
 * @file chat_stop_gate_node.cpp
 * @brief 대화 중 정지 게이트 노드
 *
 * 기능:
 * - is_chatting=true 일 때 정지 명령 지속 발행
 * - twist_mux에서 최고 우선순위(300)로 설정
 * - 대화 중 모든 주행 명령 무시
 *
 * 우선순위:
 * - twist_mux priority 300 (최고)
 *
 * 토픽:
 * - 구독: /is_chatting (Bool) - 대화 상태
 * - 발행: /cmd_vel_is_chatting (Twist) - 정지 명령
 */

#include <chrono>
#include <memory>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/bool.hpp"
#include "geometry_msgs/msg/twist.hpp"

using namespace std::chrono_literals;

/**
 * @class ChatStopGateNode
 * @brief 대화 중 로봇 정지를 보장하는 게이트 노드
 *
 * twist_mux에서 최고 우선순위를 가지며,
 * 대화 중일 때 정지 명령을 지속적으로 발행하여
 * 다른 모든 주행 명령을 무시하도록 함
 */
class ChatStopGateNode : public rclcpp::Node {
public:
  ChatStopGateNode() : Node("chat_stop_gate_node") {
    declareParameters();
    loadParameters();
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
    declare_parameter<std::string>("is_chatting_topic", "/is_chatting");
    declare_parameter<std::string>("cmd_out_topic", "/cmd_vel_is_chatting");
    declare_parameter<double>("publish_rate", 10.0);
  }

  void loadParameters() {
    is_chatting_topic_ = get_parameter("is_chatting_topic").as_string();
    cmd_out_topic_ = get_parameter("cmd_out_topic").as_string();
    publish_rate_ = get_parameter("publish_rate").as_double();

    // 유효성 검사
    if (publish_rate_ <= 0.0) {
      RCLCPP_WARN(get_logger(), "Invalid publish_rate, using default 10.0 Hz");
      publish_rate_ = 10.0;
    }
  }

  void initializePublisher() {
    pub_cmd_ = create_publisher<geometry_msgs::msg::Twist>(cmd_out_topic_, 10);
  }

  void initializeSubscriber() {
    sub_is_chatting_ = create_subscription<std_msgs::msg::Bool>(
      is_chatting_topic_,
      rclcpp::QoS(10).reliable(),
      std::bind(&ChatStopGateNode::chattingCallback, this, std::placeholders::_1)
    );
  }

  void initializeTimer() {
    // 발행 주기 계산
    auto period = std::chrono::duration<double>(1.0 / publish_rate_);

    timer_ = create_wall_timer(
      std::chrono::duration_cast<std::chrono::nanoseconds>(period),
      std::bind(&ChatStopGateNode::timerCallback, this)
    );
  }

  void logConfiguration() {
    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Chat Stop Gate Node Started");
    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Subscribe: %s", is_chatting_topic_.c_str());
    RCLCPP_INFO(get_logger(), "Publish  : %s", cmd_out_topic_.c_str());
    RCLCPP_INFO(get_logger(), "Rate     : %.1f Hz", publish_rate_);
    RCLCPP_INFO(get_logger(), "===========================================");
  }

  // =====================================================
  // 콜백 함수들
  // =====================================================

  /**
   * @brief 대화 상태 콜백
   *
   * is_chatting 토픽을 구독하여 상태 업데이트
   */
  void chattingCallback(const std_msgs::msg::Bool::SharedPtr msg) {
    const bool prev_state = is_chatting_;
    is_chatting_ = msg->data;

    // 상태 변화 시에만 로그
    if (prev_state != is_chatting_) {
      if (is_chatting_) {
        RCLCPP_INFO(get_logger(), "💬 Chatting started → Robot STOPPED");
      } else {
        RCLCPP_INFO(get_logger(), "✓ Chatting ended → Robot RELEASED");
      }
    }
  }

  /**
   * @brief 타이머 콜백
   *
   * 대화 중일 때만 정지 명령 발행
   */
  void timerCallback() {
    if (!is_chatting_) {
      return;  // 대화 중이 아니면 발행하지 않음
    }

    // 정지 명령 생성
    geometry_msgs::msg::Twist stop_cmd;
    stop_cmd.linear.x = 0.0;
    stop_cmd.linear.y = 0.0;
    stop_cmd.linear.z = 0.0;
    stop_cmd.angular.x = 0.0;
    stop_cmd.angular.y = 0.0;
    stop_cmd.angular.z = 0.0;

    pub_cmd_->publish(stop_cmd);
  }

  // =====================================================
  // 멤버 변수
  // =====================================================

  // 파라미터
  std::string is_chatting_topic_;
  std::string cmd_out_topic_;
  double publish_rate_;

  // 상태
  bool is_chatting_{false};

  // ROS 인터페이스
  rclcpp::Subscription<std_msgs::msg::Bool>::SharedPtr sub_is_chatting_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_cmd_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<ChatStopGateNode>();

  try {
    rclcpp::spin(node);
  } catch (const std::exception& e) {
    RCLCPP_ERROR(node->get_logger(), "Exception in chat_stop_gate_node: %s", e.what());
  }

  rclcpp::shutdown();
  return 0;
}
