#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
setup_file="$repo_root/ros_ws/install/setup.sh"

if ! command -v ros2 >/dev/null 2>&1; then
  echo "ros2 is not on PATH. Run this inside 'nix develop'." >&2
  exit 1
fi

if [[ ! -f "$setup_file" ]]; then
  echo "Build the workspace first with ./scripts/build-demo.sh" >&2
  exit 1
fi

# shellcheck source=/dev/null
set +u
source "$setup_file"
set -u

exec ros2 launch minimal_gz_demo sim.launch.py
