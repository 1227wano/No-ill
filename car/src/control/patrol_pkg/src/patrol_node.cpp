/**
 * @file patrol_node.cpp
 * @brief 자율 순찰 노드
 *
 * 기능:
 * - 정해진 웨이포인트들을 순환하며 순찰
 * - 사람 감지 시 순찰 일시 중지 (person_override_node가 제어)
 * - 사람이 일정 시간 감지되지 않으면 순찰 재개
 *
 * 토픽:
 * - 구독: /object_type (std_msgs/String) - YOLO 감지 결과
 * - 액션 클라이언트: /navigate_to_pose (Nav2)
 */

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <nav2_msgs/action/navigate_to_pose.hpp>
#include <std_msgs/msg/string.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>

#include <vector>
#include <string>
#include <memory>

using NavigateToPose = nav2_msgs::action::NavigateToPose;
using GoalHandleNav = rclcpp_action::ClientGoalHandle<NavigateToPose>;

/**
 * @class PatrolNode
 * @brief 2개 웨이포인트 간 순찰을 수행하는 노드
 *
 * 동작 시퀀스:
 * 1. Nav2 액션 서버 연결 대기
 * 2. 웨이포인트 1 → 2 → 1 순환
 * 3. 사람 감지 시 순찰 중지
 * 4. person_timeout 이후 순찰 재개
 */
class PatrolNode : public rclcpp::Node {
public:
  PatrolNode() : Node("patrol_node") {
    // =====================================================
    // 파라미터 선언 및 로드
    // =====================================================
    declare_parameter<double>("waypoint1_x", -3.03);
    declare_parameter<double>("waypoint1_y", -3.76);
    declare_parameter<double>("waypoint2_x", 0.91);
    declare_parameter<double>("waypoint2_y", -1.77);
    declare_parameter<double>("person_timeout", 3.0);  // 사람 감지 타임아웃 (초)
    declare_parameter<std::string>("object_type_topic", "/object_type");

    const double wp1_x = get_parameter("waypoint1_x").as_double();
    const double wp1_y = get_parameter("waypoint1_y").as_double();
    const double wp2_x = get_parameter("waypoint2_x").as_double();
    const double wp2_y = get_parameter("waypoint2_y").as_double();
    const double timeout = get_parameter("person_timeout").as_double();

    // 웨이포인트 리스트 구성
    waypoints_.push_back({wp1_x, wp1_y});
    waypoints_.push_back({wp2_x, wp2_y});

    // =====================================================
    // Nav2 액션 클라이언트 생성
    // =====================================================
    nav_client_ = rclcpp_action::create_client<NavigateToPose>(
      this,
      "navigate_to_pose"
    );

    // =====================================================
    // 객체 타입 구독 (YOLO 감지 결과)
    // =====================================================
    const std::string object_topic = get_parameter("object_type_topic").as_string();

    sub_object_type_ = create_subscription<std_msgs::msg::String>(
      object_topic,
      10,
      std::bind(&PatrolNode::objectTypeCallback, this, std::placeholders::_1)
    );

    // =====================================================
    // 메인 타이머 (1Hz)
    // =====================================================
    timer_ = create_wall_timer(
      std::chrono::seconds(1),
      std::bind(&PatrolNode::timerCallback, this)
    );

    // 초기 시간 설정
    last_person_time_ = now();

    // 로그 출력
    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Patrol Node Started");
    RCLCPP_INFO(get_logger(), "===========================================");
    RCLCPP_INFO(get_logger(), "Waypoint 1: (%.2f, %.2f)", wp1_x, wp1_y);
    RCLCPP_INFO(get_logger(), "Waypoint 2: (%.2f, %.2f)", wp2_x, wp2_y);
    RCLCPP_INFO(get_logger(), "Person timeout: %.1f seconds", timeout);
    RCLCPP_INFO(get_logger(), "Object type topic: %s", object_topic.c_str());
    RCLCPP_INFO(get_logger(), "===========================================");
  }

private:
  // =====================================================
  // 콜백 함수들
  // =====================================================

  /**
   * @brief YOLO 객체 타입 콜백
   *
   * "lying" 또는 "others" 감지 시 사람으로 판단하고 순찰 중지
   * - lying: 누워있는 사람 (낙상 가능성)
   * - others: 서있거나 앉아있는 사람
   */
  void objectTypeCallback(const std_msgs::msg::String::SharedPtr msg) {
    const std::string& object_type = msg->data;

    // 사람 관련 객체 감지 여부
    const bool is_person_detected = (object_type == "lying" || object_type == "others");

    if (is_person_detected) {
      // 마지막 감지 시간 갱신
      last_person_time_ = now();

      // 처음 감지된 경우 순찰 중지
      if (!person_detected_) {
        person_detected_ = true;
        RCLCPP_INFO(get_logger(), "👤 Person detected! Pausing patrol...");
        cancelCurrentNavigation();
      }
    }
  }

  /**
   * @brief 메인 타이머 콜백 (1Hz)
   *
   * 동작:
   * 1. Nav2 액션 서버 연결 확인
   * 2. 사람 감지 타임아웃 체크
   * 3. 순찰 진행
   */
  void timerCallback() {
    // Nav2 액션 서버 대기 (비블로킹)
    if (!nav_client_->wait_for_action_server(std::chrono::seconds(0))) {
      RCLCPP_WARN_THROTTLE(
        get_logger(),
        *get_clock(),
        5000,  // 5초마다 한 번만 출력
        "⏳ Waiting for Nav2 action server..."
      );
      return;
    }

    // 사람 감지 상태 확인
    if (person_detected_) {
      checkPersonTimeout();
      return;  // 사람 감지 중이면 순찰하지 않음
    }

    // 순찰 진행
    if (!navigating_) {
      sendNextGoal();
    }
  }

  // =====================================================
  // 헬퍼 함수들
  // =====================================================

  /**
   * @brief 사람 감지 타임아웃 체크
   *
   * person_timeout 시간 동안 사람이 감지되지 않으면 순찰 재개
   */
  void checkPersonTimeout() {
    const double timeout = get_parameter("person_timeout").as_double();
    const double elapsed = (now() - last_person_time_).seconds();

    if (elapsed > timeout) {
      person_detected_ = false;
      RCLCPP_INFO(
        get_logger(),
        "✓ Person lost for %.1f seconds. Resuming patrol...",
        elapsed
      );
    }
  }

  /**
   * @brief 다음 웨이포인트로 이동 명령 전송
   */
  void sendNextGoal() {
    const auto& [x, y] = waypoints_[current_waypoint_];

    // Goal 메시지 구성
    auto goal_msg = NavigateToPose::Goal();
    goal_msg.pose.header.frame_id = "map";
    goal_msg.pose.header.stamp = now();
    goal_msg.pose.pose.position.x = x;
    goal_msg.pose.pose.position.y = y;
    goal_msg.pose.pose.position.z = 0.0;

    // 방향은 자동으로 계산하도록 기본값 설정
    goal_msg.pose.pose.orientation.x = 0.0;
    goal_msg.pose.pose.orientation.y = 0.0;
    goal_msg.pose.pose.orientation.z = 0.0;
    goal_msg.pose.pose.orientation.w = 1.0;

    // Goal 전송 옵션 설정
    auto send_goal_options = rclcpp_action::Client<NavigateToPose>::SendGoalOptions();

    // 결과 콜백 설정
    send_goal_options.result_callback =
      std::bind(&PatrolNode::goalResultCallback, this, std::placeholders::_1);

    // 피드백 콜백 설정 (선택사항)
    send_goal_options.feedback_callback =
      [this](GoalHandleNav::SharedPtr, const std::shared_ptr<const NavigateToPose::Feedback> feedback) {
        // 주기적으로 남은 거리 출력 (옵션)
        // RCLCPP_DEBUG(get_logger(), "Distance remaining: %.2f", feedback->distance_remaining);
      };

    // Goal 전송
    RCLCPP_INFO(
      get_logger(),
      "🚀 Navigating to waypoint %zu: (%.2f, %.2f)",
      current_waypoint_ + 1, x, y
    );

    nav_client_->async_send_goal(goal_msg, send_goal_options);
    navigating_ = true;
  }

  /**
   * @brief Nav2 Goal 결과 콜백
   */
  void goalResultCallback(const GoalHandleNav::WrappedResult& result) {
    navigating_ = false;

    switch (result.code) {
      case rclcpp_action::ResultCode::SUCCEEDED:
        RCLCPP_INFO(
          get_logger(),
          "✓ Reached waypoint %zu",
          current_waypoint_ + 1
        );
        // 다음 웨이포인트로 순환
        current_waypoint_ = (current_waypoint_ + 1) % waypoints_.size();
        break;

      case rclcpp_action::ResultCode::CANCELED:
        RCLCPP_INFO(get_logger(), "⏸ Navigation canceled");
        break;

      case rclcpp_action::ResultCode::ABORTED:
        RCLCPP_WARN(get_logger(), "⚠ Navigation aborted");
        break;

      default:
        RCLCPP_ERROR(get_logger(), "❌ Navigation failed with unknown result code");
        break;
    }
  }

  /**
   * @brief 현재 진행 중인 네비게이션 취소
   */
  void cancelCurrentNavigation() {
    if (navigating_) {
      RCLCPP_INFO(get_logger(), "⏹ Canceling current navigation...");
      nav_client_->async_cancel_all_goals();
      navigating_ = false;
    }
  }

  // =====================================================
  // 멤버 변수
  // =====================================================

  // ROS 인터페이스
  rclcpp_action::Client<NavigateToPose>::SharedPtr nav_client_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_object_type_;
  rclcpp::TimerBase::SharedPtr timer_;

  // 웨이포인트 리스트
  std::vector<std::pair<double, double>> waypoints_;

  // 상태 변수
  bool person_detected_{false};    // 사람 감지 여부
  bool navigating_{false};          // 네비게이션 진행 중 여부
  rclcpp::Time last_person_time_;   // 마지막 사람 감지 시간
  size_t current_waypoint_{1};      // 현재 목표 웨이포인트 (1부터 시작 = waypoint2)
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<PatrolNode>();

  try {
    rclcpp::spin(node);
  } catch (const std::exception& e) {
    RCLCPP_ERROR(node->get_logger(), "Exception in patrol_node: %s", e.what());
  }

  rclcpp::shutdown();
  return 0;
}
