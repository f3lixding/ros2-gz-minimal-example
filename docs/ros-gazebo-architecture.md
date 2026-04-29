# ROS and Gazebo Architecture Notes

This note records the ROS 2 and Gazebo split used in this repository, along
with the practical process model and how the same architecture maps onto a real
robot.

## Main split

- `ROS 2` owns launch, the ROS topic graph, and the demo controller node.
- `Gazebo` owns the simulated world, robot physics, and Gazebo transport
  topics.
- `ros_gz_bridge` translates between ROS messages and Gazebo messages.

The important point is that the bridge is explicit. Gazebo does not
automatically understand ROS topics, and ROS does not automatically understand
Gazebo transport topics.

## What the launch file does

The launch file is [ros_ws/src/minimal_gz_demo/launch/sim.launch.py](../ros_ws/src/minimal_gz_demo/launch/sim.launch.py).

Its imports are ROS-side Python libraries:

- `launch`
- `launch_ros`
- `ament_index_python`

It starts three main pieces:

1. `gz sim -r <world.sdf>`
2. `ros_gz_bridge/parameter_bridge`
3. `minimal_gz_demo/controller`

So this file is a ROS launch file that starts Gazebo as an external process.

## What the SDF file does

The world file is [ros_ws/src/minimal_gz_demo/worlds/minimal_diff_drive.sdf](../ros_ws/src/minimal_gz_demo/worlds/minimal_diff_drive.sdf).

It defines:

- the world
- the robot model
- Gazebo system plugins
- Gazebo-side topic names used by the plugins

In particular, the `DiffDrive` plugin defines:

- command topic: `/model/minibot/cmd_vel`
- odometry topic: `/model/minibot/odometry`

Those are Gazebo transport topics. The SDF does not define the ROS bridge.

## What the bridge does

The bridge configuration is in the launch file:

- `/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock`
- `/model/minibot/cmd_vel@geometry_msgs/msg/Twist]gz.msgs.Twist`
- `/model/minibot/odometry@nav_msgs/msg/Odometry[gz.msgs.Odometry`

That means:

- Gazebo publishes `/clock`, bridge republishes it into ROS
- ROS publishes `/model/minibot/cmd_vel`, bridge converts it into Gazebo
- Gazebo publishes `/model/minibot/odometry`, bridge republishes it into ROS

So the message path for motion is:

1. ROS controller publishes `geometry_msgs/msg/Twist`
2. `parameter_bridge` converts that into `gz.msgs.Twist`
3. Gazebo `DiffDrive` subscribes to that Gazebo topic
4. Gazebo simulates the robot response
5. Gazebo `DiffDrive` publishes odometry on a Gazebo topic
6. `parameter_bridge` converts that into `nav_msgs/msg/Odometry`
7. ROS controller subscribes to the ROS odometry topic

## Processes in this repo

For one normal run, the launched process stack is:

1. `ros2 launch minimal_gz_demo sim.launch.py`
2. `gz sim -r ...`
3. `ros_gz_bridge/parameter_bridge`
4. `minimal_gz_demo/controller`
5. `gz sim server`
6. `gz sim gui`

So `gz sim` itself is a wrapper process which then spawns:

- `gz sim server`
- `gz sim gui`

## How to inspect the processes

Useful commands:

```sh
ps -eo pid,ppid,cmd | rg 'ros2 launch minimal_gz_demo|gz sim|parameter_bridge|minimal_gz_demo/controller'
```

That shows:

- the process id
- the parent process id
- the command

To inspect children of the launch process:

```sh
launch_pid=$(pgrep -f 'ros2.*launch minimal_gz_demo sim.launch.py')
pgrep -P "$launch_pid" -a
```

To inspect children of the `gz sim` wrapper:

```sh
gz_pid=$(pgrep -P "$launch_pid" -f 'gz sim -r')
pgrep -P "$gz_pid" -a
```

If `pstree` is desired and not installed in the shell:

```sh
nix shell nixpkgs#psmisc -c pstree -sap "$launch_pid"
```

## Simulation versus hardware

In simulation, the consumer of the motion command is the Gazebo plugin.

In the real robot, Gazebo disappears. The command consumer is usually a
hardware-facing ROS node or driver.

So the simulated stack is:

- ROS node publishes `/cmd_vel`
- `ros_gz_bridge` translates it
- Gazebo plugin consumes it

The hardware stack is:

- ROS node publishes `/cmd_vel`
- motor driver or base controller node consumes it
- that node talks to real hardware

Typical hardware interfaces are:

- serial
- CAN
- vendor SDKs
- GPIO or PWM
- microcontroller links

The useful architectural rule is to keep the contract stable:

- simulation backend and hardware backend should subscribe to the same command
  topics
- simulation backend and hardware backend should publish the same observation
  topics such as odometry, joint states, IMU, or TF

That way higher-level ROS logic does not need to know whether the backend is
Gazebo or a real robot.
