# launch/noili_full.launch.py
import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    # 패키지 경로
    pkg_noili_bringup = get_package_share_directory('noili_bringup')
    pkg_nav2_bringup = get_package_share_directory('nav2_bringup')
    
    # 설정 파일 경로
    twist_mux_config = os.path.join(pkg_noili_bringup, 'config', 'twist_mux.yaml')
    nav2_params = os.path.join(pkg_noili_bringup, 'config', 'nav2_params.yaml')
    map_yaml = os.path.join(pkg_noili_bringup, 'maps', 'home_map.yaml')
    
    # Launch Arguments
    use_sim_time = LaunchConfiguration('use_sim_time', default='false')
    
    # =====================================================
    # 1. 센서 레이어
    # =====================================================
    
    # 1-1) YDLIDAR
    ydlidar = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([
            PathJoinSubstitution([
                FindPackageShare('ydlidar_ros2_driver'),
                'launch',
                'ydlidar_launch.py'
            ])
        ])
    )
    
    # 1-2) Static TF: base_link → laser_frame
    static_tf = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='base_to_laser_tf',
        arguments=['0', '0', '0.1', '0', '0', '0', 'base_link', 'laser_frame']
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
            'freq': 20.0
        }]
    )
    
    # =====================================================
    # 2. Nav2 스택 (2초 딜레이 - TF 안정화 후 실행)
    # =====================================================
    
    nav2_bringup = TimerAction(
        period=2.0,  # 2초 딜레이
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
    # 3. Control 레이어 (override 노드들)
    # =====================================================
    
    # 3-1) Safety Override (라이다 기반 장애물 회피)
    safety_override = Node(
        package='noili_control',
        executable='safety_override_node',
        name='safety_override_node',
        output='screen',
        parameters=[{
            'emergency_distance': 0.5,      # 50cm 이내 긴급정지
            'slow_distance': 1.0,           # 1m 이내 감속
            'angular_gain': 1.5             # 회피 강도
        }]
    )
    
    # 3-2) Person Override (사람 추적)
    person_override = Node(
        package='noili_control',
        executable='person_override_node',
        name='person_override_node',
        output='screen',
        parameters=[{
            'target_distance': 1.5,         # 사람과 유지 거리
            'max_linear_vel': 0.3,
            'max_angular_vel': 0.5,
            'pid_kp': 1.0,
            'pid_ki': 0.0,
            'pid_kd': 0.1
        }]
    )
    
    # 3-3) Chat Stop Gate (대화중 정지)
    chat_stop_gate = Node(
        package='noili_control',
        executable='chat_stop_gate_node',
        name='chat_stop_gate_node',
        output='screen',
        parameters=[{
            'publish_rate': 10.0            # 10Hz 정지 신호
        }]
    )
    
    # =====================================================
    # 4. twist_mux (최종 속도 통합)
    # =====================================================
    
    twist_mux = Node(
        package='twist_mux',
        executable='twist_mux',
        name='twist_mux',
        output='screen',
        parameters=[twist_mux_config],
        remappings=[
            ('/cmd_vel_out', '/cmd_vel_out')  # 최종 출력
        ]
    )
    
    # =====================================================
    # 5. RViz2 (시각화)
    # =====================================================
    
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', os.path.join(pkg_noili_bringup, 'rviz', 'noili.rviz')],
        output='screen'
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
        safety_override,
        person_override,
        chat_stop_gate,
        
        # 4. twist_mux
        twist_mux,
        
        # 5. RViz (선택)
        # rviz,
    ])
