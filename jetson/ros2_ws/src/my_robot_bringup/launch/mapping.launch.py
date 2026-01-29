from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # --- Args ---
    slam_params_file = DeclareLaunchArgument(
        "slam_params_file",
        default_value="/home/jetson/ros2_ws/config/mapper_params_online_async.yaml",
        description="Full path to slam_toolbox params yaml"
    )

    use_sim_time = DeclareLaunchArgument(
        "use_sim_time",
        default_value="false",
        description="Use simulation time (should be false on real robot)"
    )

    # Optional: static tf values (edit to match your mounting)
    tf_x = DeclareLaunchArgument("tf_x", default_value="-0.10")
    tf_y = DeclareLaunchArgument("tf_y", default_value="0.0")
    tf_z = DeclareLaunchArgument("tf_z", default_value="0.02")
    tf_roll = DeclareLaunchArgument("tf_roll", default_value="0.0")
    tf_pitch = DeclareLaunchArgument("tf_pitch", default_value="0.0")
    tf_yaw = DeclareLaunchArgument("tf_yaw", default_value="0.0")

    # --- Packages ---
    ydlidar_share = get_package_share_directory("ydlidar_ros2_driver")
    slam_share = get_package_share_directory("slam_toolbox")

    ydlidar_launch = os.path.join(ydlidar_share, "launch", "ydlidar_launch.py")
    # 너가 쓰던 X4-Pro.yaml 경로 (패키지 내부)
    ydlidar_params = os.path.join(
        ydlidar_share, "params", "X4-Pro.yaml"
    )

    slam_launch = os.path.join(slam_share, "launch", "online_async_launch.py")

    # --- LiDAR driver ---
    ydlidar = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(ydlidar_launch),
        launch_arguments={
            "params_file": ydlidar_params,
        }.items()
    )

    # --- Static TF: base_link -> laser_frame ---
    static_tf = Node(
        package="tf2_ros",
        executable="static_transform_publisher",
        name="base_link_to_laser_frame_tf",
        arguments=[
            LaunchConfiguration("tf_x"),
            LaunchConfiguration("tf_y"),
            LaunchConfiguration("tf_z"),
            LaunchConfiguration("tf_roll"),
            LaunchConfiguration("tf_pitch"),
            LaunchConfiguration("tf_yaw"),
            "base_link",
            "laser_frame",
        ],
        output="screen",
    )

    # --- rf2o odom: publishes odom -> base_link TF ---
    rf2o = Node(
      package="rf2o_laser_odometry",
      executable="rf2o_laser_odometry_node",
      name="rf2o_laser_odometry",
      output="screen",
      parameters=[{
          "laser_scan_topic": "/scan",
          "publish_tf": True,
          "base_frame_id": "base_link",
          "odom_frame_id": "odom",
          # 선택: odom 토픽도 쓰고 싶으면
          "odom_topic": "/odom_rf2o",
          # 선택: 내부 처리 주기
          "freq": 10.0,
      }],
    )

    # --- slam_toolbox mapping (force use_sim_time := false by default) ---
    slam = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(slam_launch),
        launch_arguments={
            "slam_params_file": LaunchConfiguration("slam_params_file"),
            "use_sim_time": LaunchConfiguration("use_sim_time"),
        }.items()
    )

    return LaunchDescription([
        slam_params_file,
        use_sim_time,
        tf_x, tf_y, tf_z, tf_roll, tf_pitch, tf_yaw,
        ydlidar,
        static_tf,
        rf2o,
        slam,
    ])

