from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():

    pca_drive = Node(
        package="pca_drive",
        executable="pca_drive_node",
        name="pca_drive",
        output="screen",
    )

    keyboard_latch = Node(
        package="keyboard_latch_cpp",
        executable="keyboard_latch_node",
        name="keyboard_latch",
        output="screen",
        parameters=[{
            "steer_max": 1.0,
            "steer_step": 0.1,
        }],
    )

    return LaunchDescription([
        pca_drive,
        keyboard_latch,
    ])

