{
  description = "Minimal Gazebo + ROS 2 example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    ros-nixpkgs.url = "github:lopsided98/nixpkgs?ref=nix-ros";
    flake-utils.url = "github:numtide/flake-utils";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nix-ros-overlay.inputs.nixpkgs.follows = "ros-nixpkgs";
    nix-ros-gz.url = "github:f3lixding/nix-ros-gz";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    {
      nixpkgs,
      ros-nixpkgs,
      flake-utils,
      nix-ros-overlay,
      nix-ros-gz,
      zig-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            zig-overlay.overlays.default
          ];
        };

        simPkgs = import ros-nixpkgs {
          inherit system;
        };

        zig = pkgs.zigpkgs."0.16.0";

        # not making a patch for this because the latest version at the time
        # writing is already 0.16
        zls = pkgs.zls;

        sim = nix-ros-gz.lib.sim {
          pkgs = simPkgs;
          inherit system nix-ros-overlay;
          extraRosPackages = ros: [
            ros.ament-cmake
            ros.ament-cmake-core
            ros.common-interfaces
            ros.launch-ros
            ros.python-cmake-module
            ros.rclcpp
            ros.ros2launch
            ros.teleop-twist-keyboard
            ros.sensor-msgs
          ];
        };

        colcon = nix-ros-gz.lib.gen-colcon {
          inherit pkgs;
          python3Packages = sim.ros.python3Packages;
        };
      in
      {
        packages = {
          default = sim.rosEnv;
          ros-env = sim.rosEnv;
        };

        devShells.default = pkgs.mkShell {
          packages = sim.packages ++ [
            colcon
            pkgs.cmake
            pkgs.gcc
            pkgs.pkg-config
            zig
            zls
          ];

          shellHook = ''
            ${sim.shellHook}
            export DEMO_WS="$PWD/ros_ws"
            export ROS_LOCALHOST_ONLY="''${ROS_LOCALHOST_ONLY:-1}"

            if [ -f "$DEMO_WS/install/setup.sh" ]; then
              source "$DEMO_WS/install/setup.sh"
            fi

            echo "Minimal Gazebo + ROS 2 shell"
            echo "  build: ./scripts/build-demo.sh"
            echo "  launch: ./scripts/run-demo.sh"
          '';
        };
      }
    );
}
