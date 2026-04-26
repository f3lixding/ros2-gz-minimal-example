# Minimal Gazebo + ROS 2 example

This repository is a minimal working example of a ROS 2 node driving a robot in
Gazebo.

The main moving parts are:

- `nix/sim/default.nix`: Gazebo and ROS 2 shell wiring, including the Ogre
  patch set copied from `~/doodle/waterbot/nix/sim/default.nix`
- `ros_ws/src/minimal_gz_demo/worlds/minimal_diff_drive.sdf`: one tiny SDF
  world with a differential-drive robot
- `ros_ws/src/minimal_gz_demo/launch/sim.launch.py`: launches Gazebo, the
  `ros_gz_bridge`, and the demo ROS node
- `ros_ws/src/minimal_gz_demo/src/controller.cpp`: publishes `Twist` commands
  and logs bridged odometry

## Run it

```bash
nix develop path:.
./scripts/build-demo.sh
./scripts/run-demo.sh
```

Inside Gazebo you should see `minibot` drive forward, rotate, and then arc.
The controller node logs odometry to the terminal once per second.

## What to copy into your own project

1. Keep the environment layer separate from the ROS package layer.
2. Make the Gazebo side explicit in SDF:
   - world plugins
   - robot model
   - simulation plugin such as `DiffDrive`
3. Bridge only the topics you actually need.
4. Put your control node behind the bridge, not inside Gazebo.

For this example the bridge is:

- Gazebo to ROS: `/clock`
- ROS to Gazebo: `/model/minibot/cmd_vel`
- Gazebo to ROS: `/model/minibot/odometry`

That same pattern scales to sensors, joint states, TF, and custom command
topics.
