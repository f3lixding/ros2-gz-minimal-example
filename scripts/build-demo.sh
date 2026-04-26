#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
workspace_dir="$repo_root/ros_ws"

if ! command -v colcon >/dev/null 2>&1; then
  echo "colcon is not on PATH. Run this inside 'nix develop'." >&2
  exit 1
fi

cd "$workspace_dir"

colcon build \
  --symlink-install \
  --event-handlers console_direct+ \
  --base-paths src \
  "$@"
