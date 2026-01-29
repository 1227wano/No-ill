from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # --- package share paths ---
    bringup_share = get_package_share_directory("robot_bringup")
    nav2_share = get_package_share_directory("nav2_bringup")

    # --- default files inside package ---
    default_nav2_params = os.path.join(bringup_share, "config", "nav2_params.yaml")
    default_map = "/home/jetson/maps/home_map.yaml"  # 너 환경 기본값

    # --- launch arguments ---
    use_sim_time_arg = DeclareLaunchArgument(
        "use_sim_time",
        default_value="false",
        description="Use simulation clock if true"
    )

    map_arg = DeclareLaunchArgument(
        "map",
        default_value=default_map,
        description="Path to map yaml"
    )

    # ✅ use_composition을 LaunchArgument로 빼서 문자열 True/False 판정 꼬임 방지
    use_composition_arg = DeclareLaunchArgument(
        "use_composition",
        default_value="False",
        description="Use Nav2 composition if True"
    )

    # ✅ params 파일 인자
    nav2_params_file_arg = DeclareLaunchArgument(
        "nav2_params_file",
        default_value=default_nav2_params,
        description="Path to Nav2 params yaml"
    )

    # --- include localization (your package) ---
    localization_launch = os.path.join(bringup_share, "launch", "localization.launch.py")
    localization = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(localization_launch),
        launch_arguments={
            "use_sim_time": LaunchConfiguration("use_sim_time"),
            "map": LaunchConfiguration("map"),
            "params_file": LaunchConfiguration("nav2_params_file"),
        }.items(),
    )

    # --- include navigation (nav2_bringup) ---
    navigation_launch = os.path.join(nav2_share, "launch", "navigation_launch.py")
    navigation = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(navigation_launch),
        launch_arguments={
            # "namespace": "nav2",  # 지금은 루트로 쓰는 중이면 주석 유지
            "use_sim_time": LaunchConfiguration("use_sim_time"),
            "params_file": LaunchConfiguration("nav2_params_file"),
            "autostart": "true",
            "use_composition": LaunchConfiguration("use_composition"),
        }.items(),
    )

    return LaunchDescription([
        use_sim_time_arg,
        map_arg,
        use_composition_arg,
        nav2_params_file_arg,
        localization,
        navigation,
    ])

