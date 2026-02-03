#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <nav2_msgs/action/navigate_to_pose.hpp>
#include <std_msgs/msg/string.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>

#include <vector>
#include <string>

using NavigateToPose = nav2_msgs::action::NavigateToPose;
using GoalHandleNav = rclcpp_action::ClientGoalHandle<NavigateToPose>;

class PatrolNode : public rclcpp::Node {
public:
  PatrolNode() : Node("patrol_node") {
    // 파라미터
    declare_parameter<double>("waypoint1_x", -3.03);
    declare_parameter<double>("waypoint1_y", -3.76);
    declare_parameter<double>("waypoint2_x", 0.91);
    declare_parameter<double>("waypoint2_y", -1.77);
    declare_parameter<double>("person_timeout", 3.0);  // 사람 놓침 판단 시간
    declare_parameter<std::string>("object_type_topic", "/object_type");

    // waypoints 설정
    waypoints_.push_back({get_parameter("waypoint1_x").as_double(),
                          get_parameter("waypoint1_y").as_double()});
    waypoints_.push_back({get_parameter("waypoint2_x").as_double(),
                          get_parameter("waypoint2_y").as_double()});

    // Action client
    nav_client_ = rclcpp_action::create_client<NavigateToPose>(this, "navigate_to_pose");

    // object_type 구독
    const auto topic = get_parameter("object_type_topic").as_string();
    sub_type_ = create_subscription<std_msgs::msg::String>(
      topic, 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        const auto& t = msg->data;
        bool detected = (t == "lying" || t == "others");

        if (detected) {
          last_person_time_ = now();
          if (!person_detected_) {
            person_detected_ = true;
            RCLCPP_INFO(get_logger(), "Person detected, pausing patrol");
            cancelNav();
          }
        }
      });

    // 메인 타이머 (1Hz)
    timer_ = create_wall_timer(
      std::chrono::seconds(1),
      std::bind(&PatrolNode::onTimer, this));

    last_person_time_ = now();

    RCLCPP_INFO(get_logger(), "patrol_node started");
    RCLCPP_INFO(get_logger(), "  waypoint1: (%.2f, %.2f)", waypoints_[0].first, waypoints_[0].second);
    RCLCPP_INFO(get_logger(), "  waypoint2: (%.2f, %.2f)", waypoints_[1].first, waypoints_[1].second);
  }

private:
  void onTimer() {
    // Action server 연결 확인
    if (!nav_client_->wait_for_action_server(std::chrono::seconds(1))) {
      RCLCPP_WARN_THROTTLE(get_logger(), *get_clock(), 5000, "Waiting for nav2 action server...");
      return;
    }

    const double timeout = get_parameter("person_timeout").as_double();

    // 사람 감지 중이었는데, timeout 지나면 순찰 재개
    if (person_detected_) {
      double dt = (now() - last_person_time_).seconds();
      if (dt > timeout) {
        person_detected_ = false;
        RCLCPP_INFO(get_logger(), "Person lost, resuming patrol");
      } else {
        return;  // 아직 사람 따라가는 중
      }
    }

    // 순찰 중이 아니면 시작
    if (!navigating_) {
      sendNextGoal();
    }
  }

  void sendNextGoal() {
    auto& wp = waypoints_[current_waypoint_];

    auto goal_msg = NavigateToPose::Goal();
    goal_msg.pose.header.frame_id = "map";
    goal_msg.pose.header.stamp = now();
    goal_msg.pose.pose.position.x = wp.first;
    goal_msg.pose.pose.position.y = wp.second;
    goal_msg.pose.pose.orientation.w = 1.0;

    auto send_options = rclcpp_action::Client<NavigateToPose>::SendGoalOptions();
    send_options.result_callback =
      [this](const GoalHandleNav::WrappedResult& result) {
        navigating_ = false;
        if (result.code == rclcpp_action::ResultCode::SUCCEEDED) {
          RCLCPP_INFO(get_logger(), "Reached waypoint %d", current_waypoint_ + 1);
          // 다음 waypoint로
          current_waypoint_ = (current_waypoint_ + 1) % waypoints_.size();
        } else if (result.code == rclcpp_action::ResultCode::CANCELED) {
          RCLCPP_INFO(get_logger(), "Navigation canceled");
        } else {
          RCLCPP_WARN(get_logger(), "Navigation failed");
        }
      };

    RCLCPP_INFO(get_logger(), "Navigating to waypoint %d: (%.2f, %.2f)",
                current_waypoint_ + 1, wp.first, wp.second);

    nav_client_->async_send_goal(goal_msg, send_options);
    navigating_ = true;
  }

  void cancelNav() {
    if (navigating_) {
      nav_client_->async_cancel_all_goals();
      navigating_ = false;
    }
  }

  // ROS
  rclcpp_action::Client<NavigateToPose>::SharedPtr nav_client_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_type_;
  rclcpp::TimerBase::SharedPtr timer_;

  // Waypoints
  std::vector<std::pair<double, double>> waypoints_;

  // State
  bool person_detected_{false};
  bool navigating_{false};
  rclcpp::Time last_person_time_;
  size_t current_waypoint_{1};  // 시작점 스킵, 바로 도착지로
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PatrolNode>());
  rclcpp::shutdown();
  return 0;
}
