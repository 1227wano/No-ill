/**
 * @file person_override_node.cpp
 * @brief 사람 감지 및 추종/응급 대응 노드
 *
 * 기능:
 * 1. 일반 모드: 사람 감지 시 시각적 추적 (person_x 기반)
 * 2. 낙상 모드: 낙상 감지 시 접근 후 응급 대응 트리거
 * 3. LiDAR 기반 거리 측정으로 도착 판정
 *
 * 우선순위:
 * - twist_mux에서 priority 50 (navigation보다 높음)
 *
 * 토픽:
 * - 구독: /person_x (Int32) - 카메라 내 사람 X 좌표
 *        /object_type (String) - YOLO 감지 타입 ("lying", "others")
 *        /check_accident (Bool) - 낙상 사고 발생 여부
 *        /scan (LaserScan) - LiDAR 데이터
 * - 발행: /cmd_vel_person (Twist) - 추종/접근 속도 명령
 *        /fall_arrived (Bool) - 낙상 지점 도착 알림
 *        /is_chatting (Bool) - 대화 상태 (미사용)
 */

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
#include <memory>

/**
 * @class PersonOverrideNode
 * @brief 사람 추적 및 낙상 대응을 담당하는 노드
 *
 * 동작 모드:
 * 1. 일반 추적 모드: 사람을 시각적으로 추적하며 일정 거리 유지
 * 2. 낙상 대응 모드: 낙상 감지 시 즉시 접근하여 도착 신호 발행
 */
class PersonOverrideNode : public rclcpp::Node {
public:
  PersonOverrideNode() : Node("person_override_node") {
    declareParameters();
    initializePublishers();
    initializeSubscribers();
    initializeTimer();

    logConfiguration();
  }

private:
  // =====================================================
  // 초기화 함수들
  // =====================================================

  void declareParameters() {
    // 토픽 이름
    declare_parameter<std::string>("person_x_topic", "/person_x");
    declare_parameter<std::string>("object_type_topic", "/object_type");
    declare_parameter<std::string>("cmd_topic", "/cmd_vel_person");
    declare_parameter<std::string>("fall_accident_topic", "/check_accident");
    declare_parameter<std::string>("arrived_callback_topic", "/fall_arrived");
    declare_parameter<std::string>("is_chatting_topic", "/is_chatting");
    declare_parameter<std::string>("scan_topic", "/scan");

    // 시각 추적 파라미터
    declare_parameter<int>("img_width", 224);           // 입력 이미지 너비
    declare_parameter<double>("center_min_ratio", 0.4); // 중앙 범위 최소 (비율)
    declare_parameter<double>("center_max_ratio", 0.6); // 중앙 범위 최대 (비율)
    declare_parameter<double>("base_speed", 0.3);       // 기본 전진 속도 (m/s)
    declare_parameter<double>("kp", 1.2);               // 회전 제어 비례 게인
    declare_parameter<double>("max_yaw", 1.0);          // 최대 회전 속도 (rad/s)
    declare_parameter<double>("deadtime_sec", 1.0);     // 추적 끊김 타임아웃 (초)
    declare_parameter<bool>("invert_yaw", false);       // 회전 방향 반전 여부
    declare_parameter<double>("publish_hz", 20.0);      // 명령 발행 주기 (Hz)

    // 낙상 대응 파라미터
    declare_parameter<double>("fall_approach_speed", 0.15);  // 낙상 접근 속도 (m/s)
    declare_parameter<double>("fall_approach_time", 5.0);    // 최대 접근 시간 (초)

    // LiDAR 기반 거리 측정
    declare_parameter<double>("arrival_distance", 0.5);      // 낙상 도착 거리 (m)
    declare_parameter<double>("follow_stop_distance", 0.5);  // 일반 추적 정지 거리 (m)
    declare_parameter<double>("scan_angle_range", 20.0);     // 전방 감지 각도 (degree)
  }

  void initializePublishers() {
    const auto cmd_topic = get_parameter("cmd_topic").as_string();
    const auto arrived_topic = get_parameter("arrived_callback_topic").as_string();
    const auto chatting_topic = get_parameter("is_chatting_topic").as_string();

    pub_cmd_ = create_publisher<geometry_msgs::msg::Twist>(cmd_topic, 10);
    pub_fall_arrived_ = create_publisher<std_msgs::msg::Bool>(arrived_topic, 10);
    pub_is_chatting_ = create_publisher<std_msgs::msg::Bool>(chatting_topic, 10);
  }

  void initializeSubscribers() {
    const auto px_topic = get_parameter("person_x_topic").as_string();
    const auto ot_topic = get_parameter("object_type_topic").as_string();
    const auto fall_topic = get_parameter("fall_accident_topic").as_string();
    const auto scan_topic = get_parameter("scan_topic").as_string();

    // 사람 X 좌표 구독 (카메라 기반)
    sub_person_x_ = create_subscription<std_msgs::msg::Int32>(
      px_topic, 10,
      std::bind(&PersonOverrideNode::personXCallback, this, std::placeholders::_1)
    );

    // 객체 타입 구독 (YOLO)
    sub_object_type_ = create_subscription<std_msgs::msg::String>(
      ot_topic, 10,
      std::bind(&PersonOverrideNode::objectTypeCallback, this, std::placeholders::_1)
    );

    // 낙상 사고 구독
    sub_fall_accident_ = create_subscription<std_msgs::msg::Bool>(
      fall_topic, 10,
      std::bind(&PersonOverrideNode::fallAccidentCallback, this, std::placeholders::_1)
    );

    // LiDAR 스캔 구독
    sub_scan_ = create_subscription<sensor_msgs::msg::LaserScan>(
      scan_topic,
      rclcpp::SensorDataQoS(),
      std::bind(&PersonOverrideNode::scanCallback, this, std::placeholders::_1)
    );
  }

  void initializeTimer() {
    const double hz = get_parameter("publish_hz").as_double();
    const int period_ms = static_cast<int>(1000.0 / hz);

    timer_ = create_wall_timer(
      std::chrono::milliseconds(period_ms),
      std::bind(&PersonOverrideNode::timerCallback, this)
    );

    // 시간 초기화
    last_seen_ = now();
    approach_start_time_ = now();
  }

  void logConfiguration() {
    const auto px_topic = get_parameter("person_x_topic").as_string();
    const auto ot_topic = get_parameter("object_type_topic").as_string();
    const auto cmd_topic = get_parameter("cmd_topic").as_string();
    const auto fall_topic = get_parameter("fall_accident_topic").as_string();
    const auto arrived_topic = get_parameter("arrived_callback_topic").as_string();
    const auto chatting_topic = get_parameter("is_chatting_topic").as_string();
    const auto scan_topic = get_parameter("scan_topic").as_string();
    const double arrival_dist = get_parameter("arrival_distance").as_double();

    RCLCPP_INFO(get_logger(), "[PERSON] Started | arrival_dist=%.2fm", arrival_dist);
  }

  // =====================================================
  // 콜백 함수들
  // =====================================================

  /**
   * @brief 사람 X 좌표 콜백 (카메라 기반 추적)
   */
  void personXCallback(const std_msgs::msg::Int32::SharedPtr msg) {
    last_x_ = msg->data;
    last_seen_ = now();
    seen_once_ = true;
  }

  /**
   * @brief 객체 타입 콜백 (YOLO 감지)
   *
   * "lying": 누워있는 사람 (낙상 의심)
   * "others": 서있거나 앉아있는 사람
   */
  void objectTypeCallback(const std_msgs::msg::String::SharedPtr msg) {
    const std::string& object_type = msg->data;
    tracking_enabled_ = (object_type == "lying" || object_type == "others");
  }

  /**
   * @brief 낙상 사고 콜백
   *
   * true: 낙상 모드 진입
   * false: 정상 모드로 복귀
   */
  void fallAccidentCallback(const std_msgs::msg::Bool::SharedPtr msg) {
    if (msg->data && !fall_detected_) {
      // 낙상 감지
      fall_detected_ = true;
      approach_started_ = false;
      arrived_ = false;
      RCLCPP_WARN(get_logger(), "[PERSON] Fall detected, approaching");

    } else if (!msg->data && fall_detected_) {
      // 낙상 해제 (오탐 또는 처리 완료)
      fall_detected_ = false;
      approach_started_ = false;
      arrived_ = false;

      // chat_stop_gate 해제
      std_msgs::msg::Bool chatting_msg;
      chatting_msg.data = false;
      pub_is_chatting_->publish(chatting_msg);

      RCLCPP_INFO(get_logger(), "[PERSON] Fall cleared, resuming");
    }
  }

  /**
   * @brief LiDAR 스캔 콜백
   *
   * 전방 ±scan_angle_range 내의 최소 거리를 계산
   */
  void scanCallback(const sensor_msgs::msg::LaserScan::SharedPtr scan) {
    const double angle_range_deg = get_parameter("scan_angle_range").as_double();
    const double angle_range_rad = angle_range_deg * M_PI / 180.0;

    double min_distance = std::numeric_limits<double>::infinity();

    for (size_t i = 0; i < scan->ranges.size(); ++i) {
      const double angle = scan->angle_min + i * scan->angle_increment;

      // 전방 ±angle_range 범위만 체크
      if (std::abs(angle) <= angle_range_rad) {
        const double range = scan->ranges[i];

        if (range >= scan->range_min &&
            range <= scan->range_max &&
            range < min_distance) {
          min_distance = range;
        }
      }
    }

    front_distance_ = min_distance;
  }

  /**
   * @brief 메인 타이머 콜백
   */
  void timerCallback() {
    // 낙상 모드 처리
    if (fall_detected_) {
      handleFallAccident();
      return;
    }

    // 일반 추적 모드 처리
    handleNormalTracking();
  }

  // =====================================================
  // 동작 모드별 처리 함수들
  // =====================================================

  /**
   * @brief 일반 추적 모드 처리
   *
   * 1. 사람이 가까우면 정지
   * 2. deadtime 내에 추적 신호가 없으면 제어 중지
   * 3. 시각적 추적으로 사람 따라가기
   */
  void handleNormalTracking() {
    const double deadtime = get_parameter("deadtime_sec").as_double();
    const double elapsed = (now() - last_seen_).seconds();
    const double follow_stop_dist = get_parameter("follow_stop_distance").as_double();

    // 추적 정지 상태 처리
    if (follow_stopped_) {
      if (front_distance_ <= 1.0) {
        // 1m 이내면 계속 멈춤
        publishStop();
        return;
      } else {
        // 1m 이상 벌어지면 정지 해제
        follow_stopped_ = false;
        RCLCPP_INFO(get_logger(), "[PERSON] Moved away, resuming tracking");
      }
    }

    // 사람이 가까이 있으면 정지
    if (seen_once_ && elapsed <= deadtime && front_distance_ <= follow_stop_dist) {
      follow_stopped_ = true;
      publishStop();
      return;
    }

    // 추적 비활성화 상태
    if (!tracking_enabled_) {
      return;
    }

    // 한 번도 보지 못한 경우
    if (!seen_once_) {
      return;
    }

    // deadtime 초과 시 제어 중지 (twist_mux가 nav2로 전환)
    if (elapsed > deadtime) {
      follow_stopped_ = false;
      return;
    }

    // 시각적 추적 수행
    performVisualTracking();
  }

  /**
   * @brief 시각적 추적 수행
   *
   * 카메라 내 사람 X 좌표를 이용해 회전 제어
   */
  void performVisualTracking() {
    const int img_width = get_parameter("img_width").as_int();
    const double center_min_ratio = get_parameter("center_min_ratio").as_double();
    const double center_max_ratio = get_parameter("center_max_ratio").as_double();

    const int center_min = static_cast<int>(img_width * center_min_ratio);
    const int center_max = static_cast<int>(img_width * center_max_ratio);

    const double base_speed = get_parameter("base_speed").as_double();
    const double kp = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();
    const bool invert_yaw = get_parameter("invert_yaw").as_bool();

    // X 좌표를 이미지 범위로 제한
    const int x = std::clamp(last_x_, 0, img_width);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = base_speed;

    // 중앙 범위 내에 있으면 직진
    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      // 비례 제어로 회전 속도 계산
      const double center_x = img_width / 2.0;
      const double error = (static_cast<double>(x) - center_x) / center_x;  // -1~+1

      // 기본: 오른쪽(+)이면 우회전(-)
      double yaw = -kp * error;

      // 반전 옵션
      if (invert_yaw) {
        yaw = -yaw;
      }

      cmd.angular.z = std::clamp(yaw, -max_yaw, max_yaw);
    }

    pub_cmd_->publish(cmd);
  }

  /**
   * @brief 낙상 사고 처리
   *
   * 1. LiDAR 거리 기반 도착 판정
   * 2. 시간 기반 백업 도착 판정
   * 3. 시각적 추적으로 접근
   */
  void handleFallAccident() {
    if (arrived_) {
      return;
    }

    // 접근 시작 타임스탬프 설정
    if (!approach_started_) {
      approach_started_ = true;
      approach_start_time_ = now();
      RCLCPP_INFO(get_logger(), "[PERSON] Starting approach");
    }

    const double elapsed = (now() - approach_start_time_).seconds();
    const double arrival_dist = get_parameter("arrival_distance").as_double();
    const double fall_time = get_parameter("fall_approach_time").as_double();

    // 1. LiDAR 거리 기반 도착 판정 (우선)
    if (front_distance_ <= arrival_dist) {
      triggerArrival("LiDAR distance");
      return;
    }

    // 2. 시간 기반 백업 도착 판정
    if (elapsed >= fall_time) {
      triggerArrival("time-based fallback");
      return;
    }

    // 3. 시각적 추적 기반 접근
    performFallApproach();
  }

  /**
   * @brief 낙상 지점 접근 수행
   */
  void performFallApproach() {
    const int img_width = get_parameter("img_width").as_int();
    const double center_min_ratio = get_parameter("center_min_ratio").as_double();
    const double center_max_ratio = get_parameter("center_max_ratio").as_double();

    const int center_min = static_cast<int>(img_width * center_min_ratio);
    const int center_max = static_cast<int>(img_width * center_max_ratio);

    const double fall_speed = get_parameter("fall_approach_speed").as_double();
    const double kp = get_parameter("kp").as_double();
    const double max_yaw = get_parameter("max_yaw").as_double();
    const bool invert_yaw = get_parameter("invert_yaw").as_bool();

    const int x = std::clamp(last_x_, 0, img_width);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = fall_speed;  // 느린 속도로 접근

    if (x >= center_min && x <= center_max) {
      cmd.angular.z = 0.0;
    } else {
      const double center_x = img_width / 2.0;
      const double error = (static_cast<double>(x) - center_x) / center_x;

      double yaw = -kp * error;
      if (invert_yaw) {
        yaw = -yaw;
      }

      cmd.angular.z = std::clamp(yaw, -max_yaw, max_yaw);
    }

    pub_cmd_->publish(cmd);
  }

  /**
   * @brief 도착 트리거 (낙상 지점 도착)
   */
  void triggerArrival(const std::string& reason) {
    publishStop();

    // 도착 신호 발행
    std_msgs::msg::Bool arrived_msg;
    arrived_msg.data = true;
    pub_fall_arrived_->publish(arrived_msg);

    arrived_ = true;

    RCLCPP_INFO(get_logger(), "[PERSON] Arrived (%s)", reason.c_str());
  }

  /**
   * @brief 정지 명령 발행
   */
  void publishStop() {
    geometry_msgs::msg::Twist stop_cmd;
    stop_cmd.linear.x = 0.0;
    stop_cmd.angular.z = 0.0;
    pub_cmd_->publish(stop_cmd);
  }

  // =====================================================
  // 멤버 변수
  // =====================================================

  // ROS 인터페이스
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_cmd_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_fall_arrived_;
  rclcpp::Publisher<std_msgs::msg::Bool>::SharedPtr pub_is_chatting_;

  rclcpp::Subscription<std_msgs::msg::Int32>::SharedPtr sub_person_x_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_object_type_;
  rclcpp::Subscription<std_msgs::msg::Bool>::SharedPtr sub_fall_accident_;
  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr sub_scan_;

  rclcpp::TimerBase::SharedPtr timer_;

  // 추적 상태
  bool tracking_enabled_{false};   // YOLO에서 사람 감지 여부
  bool seen_once_{false};           // 한 번이라도 사람을 본 적 있는지
  int last_x_{160};                 // 마지막으로 본 X 좌표
  rclcpp::Time last_seen_;          // 마지막 감지 시간
  bool follow_stopped_{false};      // 추적 중 정지 상태

  // 낙상 대응 상태
  bool fall_detected_{false};       // 낙상 감지 여부
  bool approach_started_{false};    // 접근 시작 여부
  bool arrived_{false};             // 도착 여부
  rclcpp::Time approach_start_time_; // 접근 시작 시간

  // LiDAR 데이터
  double front_distance_{std::numeric_limits<double>::infinity()};  // 전방 최소 거리
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<PersonOverrideNode>();

  try {
    rclcpp::spin(node);
  } catch (const std::exception& e) {
    RCLCPP_ERROR(node->get_logger(), "Exception in person_override_node: %s", e.what());
  }

  rclcpp::shutdown();
  return 0;
}
