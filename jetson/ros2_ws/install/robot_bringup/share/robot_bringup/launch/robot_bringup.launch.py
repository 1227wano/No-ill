from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    use_sim_time = LaunchConfiguration('use_sim_time')
    mode = LaunchConfiguration('mode')  # mapping / localization / nav

    pkg_share = get_package_share_directory('robot_bringup')
    params_dir = os.path.join(pkg_share, 'params')

    ld = LaunchDescription()

    ld.add_action(DeclareLaunchArgument('use_sim_time', default_value='false'))
    ld.add_action(DeclareLaunchArgument('mode', default_value='nav'))

    # TODO: 여기부터 네가 쓰는 실제 노드/launch로 채워넣으면 됨

    # 예: lidar 드라이버(네가 쓰던 ydlidar launch)
    # IncludeLaunchDescription로 외부 패키지 launch 호출
    # (ydlidar_ros2_driver가 설치/빌드돼 있어야 함)
    # ld.add_action(IncludeLaunchDescription(
    #     PythonLaunchDescriptionSource(
    #         os.path.join(get_package_share_directory('ydlidar_ros2_driver'), 'launch', 'ydlidar_launch.py')
    #     ),
    #     launch_arguments={'params_file': os.path.join(
    #         get_package_share_directory('ydlidar_ros2_driver'),
    #         'params', 'X4-Pro.yaml'
    #     )}.items()
    # ))

    return ld
