# launch/no_ill_full.launch.py
import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, TimerAction, ExecuteProcess
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    # 패키지 경로
    pkg_no_ill_bringup = get_package_share_directory('no_ill_bringup')
    pkg_nav2_bringup = get_package_share_directory('nav2_bringup')
    
    # 설정 파일 경로
    twist_mux_config = os.path.join(pkg_no_ill_bringup, 'config', 'twist_mux.yaml')
    nav2_params = os.path.join(pkg_no_ill_bringup, 'config', 'nav2_params.yaml')
    map_yaml = os.path.join(pkg_no_ill_bringup, 'maps', 'home_map.yaml')
    
    # Launch Arguments
    use_sim_time = LaunchConfiguration('use_sim_time', default='false')
    
    # =====================================================
    # 1. 센서 레이어
    # =====================================================
    
    # 1-1) YDLIDAR
    ydlidar_share = get_package_share_directory("ydlidar_ros2_driver")
    ydlidar_launch = os.path.join(ydlidar_share, "launch", "ydlidar_launch.py")
    ydlidar_params = os.path.join(ydlidar_share, "params", "X4-Pro.yaml")

    ydlidar = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(ydlidar_launch),
        launch_arguments={
            "params_file": ydlidar_params,
        }.items()
    )
    
    # 1-2) Static TF: base_link → laser_frame
    static_tf = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='base_to_laser_tf',
        arguments=['-0.1', '0', '0.1', '0', '0', '0', 'base_link', 'laser_frame'],
        parameters=[{'use_sim_time': False}]
    )
    
    # 1-3) rf2o 오도메트리
    rf2o_odom = Node(
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
    # 2. Nav2 스택 (2초 딜레이)
    # =====================================================
    
    nav2_bringup = TimerAction(
        period=2.0,
        actions=[
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource([
                    os.path.join(pkg_nav2_bringup, 'launch', 'bringup_launch.py')
                ]),
                launch_arguments={
                    'map': map_yaml,
                    'use_sim_time': use_sim_time,
                    'params_file': nav2_params,
                    'autostart': 'true'
                }.items()
            )
        ]
    )
    
    # =====================================================
    # 3. Control 레이어
    # =====================================================
    
    # 3-1) Person Override
    person_override = Node(
        package='person_override_pkg',
        executable='person_override_node',
        name='person_override_node',
        output='screen',
        parameters=[{
            'base_speed': 0.3,
            'kp': 1.2,
            'max_yaw': 1.0,
            'invert_yaw': True,
            'follow_stop_distance': 0.8,
            'scan_angle_range': 25.0,
            'deadtime_sec': 1.0
        }]
    )
    
    # 3-2) Safety Override (장애물 회피)
    safety_override = Node(
        package='safety_override_pkg',
        executable='safety_override_node',
        name='safety_override_node',
        output='screen',
        parameters=[{
            'scan_topic': '/scan',
            'cmd_topic': '/cmd_vel_safety',
            'slow_dist': 0.50,        # 50cm 이내: 감속 + 회피
            'reverse_dist': 0.30,     # 30cm 이내: 후진 + 회피
            'min_fwd': 0.30,          # 감속 시 최소 전진 속도
            'rev_speed': -0.30,       # 후진 속도
            'max_yaw': 1.0,
            'yaw_slow': 0.8,          # 감속 시 회피 yaw
            'yaw_reverse': 0.6,       # 후진 시 회피 yaw (반대방향으로 적용됨)
            'sector_front_deg': 15.0, # -15도 ~ +15도 전방 감지
            'publish_hz': 20.0
        }]
    )

    # 3-3) Chat Stop Gate
    chat_stop_gate = Node(
        package='chat_stop_gate',
        executable='chat_stop_gate_node',
        name='chat_stop_gate_node',
        output='screen',
        parameters=[{
            'publish_rate': 10.0
        }]
    )
    
    # =====================================================
    # 4. twist_mux
    # =====================================================
    
    twist_mux = Node(
        package='twist_mux',
        executable='twist_mux',
        name='twist_mux',
        output='screen',
        parameters=[twist_mux_config]
    )
    
    # =====================================================
    # 5. pca_driver (모터 제어)
    # =====================================================
    
    pca_driver = Node(
        package='pca_drive',
        executable='pca_drive_node',
        name='pca_driver',
        output='screen',
        remappings=[
            ('/cmd_vel', '/cmd_vel_out')  # twist_mux 출력을 받음
        ]
    )
    
    # =====================================================
    # 6. YOLO Detector (카메라 감지)
    # =====================================================

    yolo_detector = Node(
        package='yolo_detector',
        executable='detect_node',
        name='yolo_detector',
        output='screen'
    )

    # =====================================================
    # 7. Fall Accident Judgement (낙상 판단)
    # =====================================================

    fall_judge = Node(
        package='fall_accident_judgement',
        executable='judgement_node',
        name='judgement_node',
        output='screen'
    )

    # =====================================================
    # 8. Emergency Response (낙상 대응)
    # =====================================================

    emergency_response = Node(
        package='emergency_response',
        executable='emergency_response_node',
        name='emergency_response_node',
        output='screen'
    )

    # =====================================================
    # 8. Upload Accident (사고 이미지 업로드)
    # =====================================================

    upload_accident = Node(
        package='upload_accident',
        executable='upload_accident_node',
        name='upload_accident_node',
        output='screen'
    )

    # =====================================================
    # 9. LLM (대화)
    # =====================================================

    llm_node = Node(
        package='llm',
        executable='llm_node',
        name='llm_node',
        output='screen'
    )

    # =====================================================
    # 10. STT (음성인식)
    # =====================================================

    stt_node = Node(
        package='stt',
        executable='stt_node',
        name='stt_node',
        output='screen'
    )

    # =====================================================
    # 11. TTS (음성합성)
    # =====================================================

    tts_node = Node(
        package='tts',
        executable='tts_node',
        name='tts_node',
        output='screen'
    )

    # =====================================================
    # 12. RViz2
    # =====================================================

    rviz2 = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', os.path.join(pkg_no_ill_bringup, 'rviz', 'no_ill.rviz')],
        output='screen'
    )
    
    # =====================================================
    # 13. 초기 위치 자동 발행 (8초 후)
    # =====================================================

    initial_pose_cmd = TimerAction(
        period=8.0,
        actions=[
            ExecuteProcess(
                cmd=['ros2', 'topic', 'pub', '/initialpose',
                     'geometry_msgs/msg/PoseWithCovarianceStamped',
                     '{header: {frame_id: "map"}, pose: {pose: {position: {x: -3.027, y: -3.758, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.707, w: 0.707}}, covariance: [0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06853891945200942]}}',
                     '--once'],
                shell=False
            )
        ]
    )

    # =====================================================
    # 14. Patrol Node (Nav2 준비 후 15초 딜레이)
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
                    'waypoint1_x': -3.03,
                    'waypoint1_y': -3.76,
                    'waypoint2_x': 0.91,
                    'waypoint2_y': -1.77,
                    'person_timeout': 3.0
                }]
            )
        ]
    )
    
    # =====================================================
    # LaunchDescription
    # =====================================================
    
    return LaunchDescription([
        # Arguments
        DeclareLaunchArgument('use_sim_time', default_value='false'),
        
        # 1. 센서 (즉시 실행)
        ydlidar,
        static_tf,
        rf2o_odom,
        
        # 2. Nav2 (2초 딜레이)
        nav2_bringup,
        
        # 3. Control
        person_override,
        safety_override,
        chat_stop_gate,
        
        # 4. twist_mux & pca_driver
        twist_mux,
        pca_driver,

        # 5. YOLO Detector
        yolo_detector,

        # 6. Fall Accident Judgement
        fall_judge,

        # 7. Emergency Response
        emergency_response,

        # 7-1. Upload Accident
        upload_accident,

        # 7. LLM
        llm_node,

        # 8. STT
        stt_node,

        # 9. TTS
        tts_node,

        # 10. RViz
        rviz2,

        # 8. 초기 위치 (5초 후 자동)
        initial_pose_cmd,

        # 9. Patrol (10초 후 시작)
        patrol_node,
    ])
