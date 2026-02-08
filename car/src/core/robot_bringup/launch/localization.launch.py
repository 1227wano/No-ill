from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # --- Args ---
    use_sim_time = DeclareLaunchArgument(
        "use_sim_time",
        default_value="false",
        description="Use simulation time (false on real robot)"
    )

    map_yaml = DeclareLaunchArgument(
        "map",
        default_value="/home/jetson/ros2_ws/maps/home_map.yaml",
        description="Full path to map yaml"
    )

    amcl_params = DeclareLaunchArgument(
        "amcl_params_file",
        default_value="/home/jetson/ros2_ws/config/amcl.yaml",
        description="Full path to AMCL params yaml"
    )

    # static tf values (base_link -> laser_frame)
    tf_x = DeclareLaunchArgument("tf_x", default_value="-0.10")
    tf_y = DeclareLaunchArgument("tf_y", default_value="0.0")
    tf_z = DeclareLaunchArgument("tf_z", default_value="0.02")
    tf_roll = DeclareLaunchArgument("tf_roll", default_value="0.0")
    tf_pitch = DeclareLaunchArgument("tf_pitch", default_value="0.0")
    tf_yaw = DeclareLaunchArgument("tf_yaw", default_value="0.0")

    # --- Packages ---
    ydlidar_share = get_package_share_directory("ydlidar_ros2_driver")
    nav2_bringup_share = get_package_share_directory("nav2_bringup")

    ydlidar_launch = os.path.join(ydlidar_share, "launch", "ydlidar_launch.py")
    ydlidar_params = os.path.join(ydlidar_share, "params", "X4-Pro.yaml")

    # --- LiDAR driver ---
    ydlidar = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(ydlidar_launch),
        launch_arguments={"params_file": ydlidar_params}.items()
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
            "odom_topic": "/odom",
            "freq": 10.0,
        }],
    )

    # --- Map server ---
    map_server = Node(
        package="nav2_map_server",
        executable="map_server",
        name="map_server",
        output="screen",
        parameters=[{
            "use_sim_time": LaunchConfiguration("use_sim_time"),
            "yaml_filename": LaunchConfiguration("map"),
        }],
    )

    # --- AMCL ---
    amcl = Node(
        package="nav2_amcl",
        executable="amcl",
        name="amcl",
        output="screen",
        parameters=[LaunchConfiguration("amcl_params_file"),
                    {"use_sim_time": LaunchConfiguration("use_sim_time")}],
    )

    # --- lifecycle manager (map_server, amcl) ---
    lifecycle = Node(
        package="nav2_lifecycle_manager",
        executable="lifecycle_manager",
        name="lifecycle_manager_localization",
        output="screen",
        parameters=[{
            "use_sim_time": LaunchConfiguration("use_sim_time"),
            "autostart": True,
            "node_names": ["map_server", "amcl"],
        }],
    )

    return LaunchDescription([
        use_sim_time,
        map_yaml,
        amcl_params,
        tf_x, tf_y, tf_z, tf_roll, tf_pitch, tf_yaw,
        ydlidar,
        static_tf,
        rf2o,
        map_server,
        amcl,
        lifecycle,
    ])

