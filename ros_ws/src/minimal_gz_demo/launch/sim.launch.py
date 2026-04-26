import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import EmitEvent, ExecuteProcess, RegisterEventHandler, TimerAction
from launch.event_handlers import OnProcessExit
from launch.events import Shutdown
from launch_ros.actions import Node


def generate_launch_description():
    pkg_share = get_package_share_directory("minimal_gz_demo")
    world_path = os.path.join(pkg_share, "worlds", "minimal_diff_drive.sdf")

    gazebo = ExecuteProcess(
        cmd=["gz", "sim", "-r", world_path],
        output="screen",
    )

    bridge = Node(
        package="ros_gz_bridge",
        executable="parameter_bridge",
        arguments=[
            "/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock",
            "/model/minibot/cmd_vel@geometry_msgs/msg/Twist]gz.msgs.Twist",
            "/model/minibot/odometry@nav_msgs/msg/Odometry[gz.msgs.Odometry",
        ],
        output="screen",
    )

    controller = Node(
        package="minimal_gz_demo",
        executable="controller",
        parameters=[{"use_sim_time": True}],
        output="screen",
    )

    shutdown_on_gazebo_exit = RegisterEventHandler(
        OnProcessExit(
            target_action=gazebo,
            on_exit=[EmitEvent(event=Shutdown())],
        )
    )

    return LaunchDescription(
        [
            gazebo,
            bridge,
            TimerAction(period=2.0, actions=[controller]),
            shutdown_on_gazebo_exit,
        ]
    )
