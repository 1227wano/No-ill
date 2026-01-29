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
        arguments=['0.1', '0', '0.1', '0', '0', '3.141592', 'base_link', 'laser_frame'],
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
    
    # 3-1) Safety Override
    safety_override = Node(
        package='safety_override_pkg',
        executable='safety_override_node',
        name='safety_override_node',
        output='screen',
        parameters=[{
            'emergency_distance': 0.5,
            'slow_distance': 1.0,
            'angular_gain': 1.5
        }]
    )
    
    # 3-2) Person Override
    person_override = Node(
        package='person_override_pkg',
        executable='person_override_node',
        name='person_override_node',
        output='screen',
        parameters=[{
            'target_distance': 1.5,
            'max_linear_vel': 0.3,
            'max_angular_vel': 0.5,
            'pid_kp': 1.0,
            'pid_ki': 0.0,
            'pid_kd': 0.1
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
    # 6. RViz2
    # =====================================================
    
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', os.path.join(pkg_no_ill_bringup, 'rviz', 'no_ill.rviz')],
        output='screen'
    )
    
    # =====================================================
    # 7. 초기 위치 자동 발행 (5초 후)
    # =====================================================
    
    initial_pose_cmd = TimerAction(
        period=5.0,
        actions=[
            ExecuteProcess(
                cmd=['ros2', 'topic', 'pub', '/initialpose', 
                     'geometry_msgs/msg/PoseWithCovarianceStamped',
                     '{header: {frame_id: "map"}, pose: {pose: {position: {x: 0.0, y: 0.0, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}, covariance: [0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06853891945200942]}}',
                     '--once'],
                shell=False
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
        safety_override,
        person_override,
        chat_stop_gate,
        
        # 4. twist_mux & pca_driver
        twist_mux,
        pca_driver,
        
        # 5. RViz
        #rviz,
        
        # 6. 초기 위치 (5초 후 자동)
        initial_pose_cmd,
    ])
