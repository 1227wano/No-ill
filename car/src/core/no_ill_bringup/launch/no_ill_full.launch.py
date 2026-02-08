#!/usr/bin/env python3
"""
No-Ill 자율주행 케어 로봇 - 메인 런치 파일

이 파일은 전체 시스템을 시작합니다:
1. 센서 레이어 (LiDAR, 오도메트리)
2. Navigation2 스택
3. 제어 레이어 (안전 오버라이드, 사람 감지)
4. 인식 레이어 (YOLO, 낙상 감지)
5. AI 레이어 (LLM, STT, TTS)
6. 응급 대응 시스템
"""

import os
from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument,
    IncludeLaunchDescription,
    TimerAction,
    ExecuteProcess
)
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    """메인 런치 디스크립션 생성"""

    # =====================================================
    # 패키지 및 설정 파일 경로
    # =====================================================
    pkg_no_ill_bringup = get_package_share_directory('no_ill_bringup')
    pkg_nav2_bringup = get_package_share_directory('nav2_bringup')
    pkg_ydlidar = get_package_share_directory('ydlidar_ros2_driver')

    # 설정 파일
    config_dir = os.path.join(pkg_no_ill_bringup, 'config')
    twist_mux_config = os.path.join(config_dir, 'twist_mux.yaml')
    nav2_params = os.path.join(config_dir, 'nav2_params.yaml')
    map_yaml = os.path.join(pkg_no_ill_bringup, 'maps', 'home_map.yaml')
    rviz_config = os.path.join(pkg_no_ill_bringup, 'rviz', 'no_ill.rviz')

    # 런치 인자
    use_sim_time = LaunchConfiguration('use_sim_time', default='false')
    autostart = LaunchConfiguration('autostart', default='true')

    # =====================================================
    # 1. 센서 레이어
    # =====================================================

    # YDLiDAR X4-Pro
    ydlidar_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_ydlidar, 'launch', 'ydlidar_launch.py')
        ),
        launch_arguments={
            'params_file': os.path.join(pkg_ydlidar, 'params', 'X4-Pro.yaml'),
        }.items()
    )

    # Static Transform: base_link → laser_frame
    base_to_laser_tf = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='base_to_laser_tf',
        arguments=['0.1', '0', '0.1', '0', '0', '0', 'base_link', 'laser_frame'],
        parameters=[{'use_sim_time': use_sim_time}]
    )

    # RF2O Laser Odometry (레이저 기반 오도메트리)
    laser_odometry = Node(
        package='rf2o_laser_odometry',
        executable='rf2o_laser_odometry_node',
        name='laser_odometry',
        output='screen',
        parameters=[{
            'laser_scan_topic': '/scan',
            'odom_topic': '/odom',
            'publish_tf': True,
            'base_frame_id': 'base_link',
            'odom_frame_id': 'odom',
            'init_pose_from_topic': '',
            'freq': 10.0
        }]
    )

    # =====================================================
    # 2. Navigation2 스택 (센서 준비 후 2초 딜레이)
    # =====================================================

    nav2_bringup = TimerAction(
        period=2.0,
        actions=[
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource(
                    os.path.join(pkg_nav2_bringup, 'launch', 'bringup_launch.py')
                ),
                launch_arguments={
                    'map': map_yaml,
                    'use_sim_time': use_sim_time,
                    'params_file': nav2_params,
                    'autostart': autostart
                }.items()
            )
        ]
    )

    # =====================================================
    # 3. 제어 레이어 (다층 안전 시스템)
    # =====================================================

    # 3-1) Person Override: 사람 감지 시 정지/추종
    person_override = Node(
        package='person_override_pkg',
        executable='person_override_node',
        name='person_override_node',
        output='screen',
        parameters=[{
            'base_speed': 0.3,              # 기본 이동 속도 (m/s)
            'kp': 1.2,                      # 회전 제어 비례 게인
            'max_yaw': 1.0,                 # 최대 회전 속도 (rad/s)
            'invert_yaw': True,             # 회전 방향 반전
            'follow_stop_distance': 0.8,    # 정지 거리 (m)
            'scan_angle_range': 25.0,       # 전방 감지 각도 (degree)
            'deadtime_sec': 1.0             # 반응 지연 시간 (초)
        }]
    )

    # 3-2) Safety Override: 장애물 회피
    safety_override = Node(
        package='safety_override_pkg',
        executable='safety_override_node',
        name='safety_override_node',
        output='screen',
        parameters=[{
            'scan_topic': '/scan',
            'cmd_topic': '/cmd_vel_safety',
            'slow_dist': 0.50,              # 감속 시작 거리 (m)
            'reverse_dist': 0.30,           # 후진 시작 거리 (m)
            'min_fwd': 0.30,                # 최소 전진 속도 (m/s)
            'rev_speed': -0.30,             # 후진 속도 (m/s)
            'max_yaw': 1.0,                 # 최대 회전 속도 (rad/s)
            'yaw_slow': 0.8,                # 감속 시 회피 회전 속도
            'yaw_reverse': 0.6,             # 후진 시 회피 회전 속도
            'sector_front_deg': 15.0,       # 전방 감지 섹터 각도
            'publish_hz': 20.0              # 명령 발행 주기 (Hz)
        }]
    )

    # 3-3) Chat Stop Gate: 대화 중 정지
    chat_stop_gate = Node(
        package='chat_stop_gate',
        executable='chat_stop_gate_node',
        name='chat_stop_gate_node',
        output='screen',
        parameters=[{
            'publish_rate': 10.0            # 발행 주기 (Hz)
        }]
    )

    # =====================================================
    # 4. Twist Multiplexer & 모터 드라이버
    # =====================================================

    # Twist Mux: 다중 속도 명령 우선순위 처리
    twist_mux = Node(
        package='twist_mux',
        executable='twist_mux',
        name='twist_mux',
        output='screen',
        parameters=[twist_mux_config],
        remappings=[
            ('cmd_vel_out', '/cmd_vel_out')
        ]
    )

    # PCA9685 모터 드라이버
    pca_driver = Node(
        package='pca_drive',
        executable='pca_drive_node',
        name='pca_driver',
        output='screen',
        remappings=[
            ('/cmd_vel', '/cmd_vel_out')    # twist_mux 출력 구독
        ]
    )

    # =====================================================
    # 5. 인식 레이어
    # =====================================================

    # YOLO 객체 감지 (사람, 낙상 자세)
    yolo_detector = Node(
        package='yolo_detector',
        executable='detect_node',
        name='yolo_detector',
        output='screen'
    )

    # 낙상 판단 로직
    fall_judgement = Node(
        package='fall_accident_judgement',
        executable='judgement_node',
        name='fall_judgement_node',
        output='screen'
    )

    # =====================================================
    # 6. 응급 대응 시스템
    # =====================================================

    # 응급 상황 대응 (알림, 정지)
    emergency_response = Node(
        package='emergency_response',
        executable='emergency_response_node',
        name='emergency_response_node',
        output='screen'
    )

    # 사고 이미지 서버 업로드
    upload_accident = Node(
        package='upload_accident',
        executable='upload_accident_node',
        name='upload_accident_node',
        output='screen',
        parameters=[{
            'upload_url': 'http://i14a301.p.ssafy.io:8080/api/events/report',
            'request_timeout': 10.0
        }]
    )

    # =====================================================
    # 7. AI 음성 인터페이스
    # =====================================================

    # LLM 대화 처리
    llm_node = Node(
        package='llm',
        executable='llm_node',
        name='llm_node',
        output='screen'
    )

    # 음성 인식 (Speech-to-Text)
    stt_node = Node(
        package='stt',
        executable='stt_node',
        name='stt_node',
        output='screen'
    )

    # 음성 합성 (Text-to-Speech)
    tts_node = Node(
        package='tts',
        executable='tts_node',
        name='tts_node',
        output='screen'
    )

    # =====================================================
    # 8. 시각화 (RViz2)
    # =====================================================

    rviz2 = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', rviz_config],
        output='screen'
    )

    # =====================================================
    # 9. 초기 위치 자동 설정 (Nav2 준비 후 8초)
    # =====================================================

    # 홈 맵의 초기 위치: (-3.027, -3.758)
    set_initial_pose = TimerAction(
        period=8.0,
        actions=[
            ExecuteProcess(
                cmd=[
                    'ros2', 'topic', 'pub', '/initialpose',
                    'geometry_msgs/msg/PoseWithCovarianceStamped',
                    '{header: {frame_id: "map"}, '
                    'pose: {pose: {position: {x: -3.027, y: -3.758, z: 0.0}, '
                    'orientation: {x: 0.0, y: 0.0, z: 0.707, w: 0.707}}, '
                    'covariance: [0.25, 0.0, 0.0, 0.0, 0.0, 0.0, '
                    '0.0, 0.25, 0.0, 0.0, 0.0, 0.0, '
                    '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, '
                    '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, '
                    '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, '
                    '0.0, 0.0, 0.0, 0.0, 0.0, 0.06853891945200942]}}',
                    '--once'
                ],
                shell=False
            )
        ]
    )

    # =====================================================
    # 10. 순찰 시작 (Nav2 완전 준비 후 15초)
    # =====================================================

    patrol_node = TimerAction(
        period=15.0,
        actions=[
            Node(
                package='patrol_pkg',
                executable='patrol_node',
                name='patrol_node',
                output='screen',
                parameters=[{
                    'waypoint1_x': -3.03,       # 웨이포인트 1 X 좌표
                    'waypoint1_y': -3.76,       # 웨이포인트 1 Y 좌표
                    'waypoint2_x': 0.91,        # 웨이포인트 2 X 좌표
                    'waypoint2_y': -1.77,       # 웨이포인트 2 Y 좌표
                    'person_timeout': 3.0       # 사람 감지 대기 시간 (초)
                }]
            )
        ]
    )

    # =====================================================
    # LaunchDescription 구성
    # =====================================================

    return LaunchDescription([
        # Launch Arguments
        DeclareLaunchArgument(
            'use_sim_time',
            default_value='false',
            description='Use simulation (Gazebo) clock if true'
        ),
        DeclareLaunchArgument(
            'autostart',
            default_value='true',
            description='Automatically startup the nav2 stack'
        ),

        # Layer 1: 센서 (즉시 실행)
        ydlidar_launch,
        base_to_laser_tf,
        laser_odometry,

        # Layer 2: Navigation2 (2초 딜레이)
        nav2_bringup,

        # Layer 3: 제어 (즉시 실행)
        person_override,
        safety_override,
        chat_stop_gate,
        twist_mux,
        pca_driver,

        # Layer 4: 인식 (즉시 실행)
        yolo_detector,
        fall_judgement,

        # Layer 5: 응급 대응 (즉시 실행)
        emergency_response,
        upload_accident,

        # Layer 6: AI 음성 (즉시 실행)
        llm_node,
        stt_node,
        tts_node,

        # Layer 7: 시각화 (즉시 실행)
        rviz2,

        # Layer 8: 초기화 (8초 후)
        set_initial_pose,

        # Layer 9: 순찰 시작 (15초 후)
        patrol_node,
    ])
