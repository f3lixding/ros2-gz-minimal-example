# Zig Lidar Handler Ideas

This project can keep ROS/Gazebo-specific code in C++ and put the local robot decision logic in Zig.

A useful split is:

```text
ROS/C++: subscribe to LaserScan, convert to FFI-safe struct, publish Twist
Zig: process lidar scan, keep behavior state, return DriveCommand
```

## Main Responsibility

Make `LaserRadarHandler` the robot's local obstacle-avoidance brain:

```text
LaserScanFFISafe -> internal state/memory -> DriveCommand
```

The Zig component should not need to know about ROS messages, nodes, publishers, or subscribers. It should receive plain data and return a plain command.

## Good Stateful Responsibilities

### 1. Track obstacle state over time

Instead of reacting to a single scan, remember whether obstacles have appeared across multiple scans.

Possible state:

```zig
front_blocked_count: usize,
front_clear_count: usize,
last_front_distance: f32,
last_left_distance: f32,
last_right_distance: f32,
```

Example behavior:

```text
Only consider the front blocked if it is blocked for 3 scans in a row.
Only resume driving forward if the front is clear for 5 scans in a row.
```

This prevents jitter from noisy or occasional readings.

### 2. Keep a behavior mode / state machine

A simple state machine is a good thing to experiment with.

Example modes:

```zig
const Mode = enum {
    drive_forward,
    slow_down,
    turn_left,
    turn_right,
    stop,
};
```

Possible handler state:

```zig
mode: Mode,
ticks_in_mode: usize,
```

Example behavior:

```text
drive_forward:
  if obstacle ahead -> choose turn_left or turn_right

turn_left:
  keep turning for at least N ticks
  if front is clear -> drive_forward

turn_right:
  keep turning for at least N ticks
  if front is clear -> drive_forward

stop:
  if clear for several scans -> drive_forward
```

### 3. Summarize lidar sectors

Convert the raw lidar rays into a few meaningful regions:

```text
left
front_left
front
front_right
right
```

Then keep the closest obstacle in each region:

```zig
const ScanSummary = struct {
    left_min: f32,
    front_left_min: f32,
    front_min: f32,
    front_right_min: f32,
    right_min: f32,
};
```

Decision logic becomes easier:

```text
if front_min < 0.5 -> blocked
if left_min > right_min -> turn left
else turn right
```

### 4. Keep past drive commands

Store previous commands and use them for smoothing.

Example smoothing idea:

```text
new_cmd.linear_x  = 0.7 * previous.linear_x  + 0.3 * desired.linear_x
new_cmd.angular_z = 0.7 * previous.angular_z + 0.3 * desired.angular_z
```

This avoids sudden jumps like going directly from hard-left to hard-right.

### 5. Detect stuck behavior

The handler can remember how long it has been trying the same behavior.

Possible state:

```zig
turning_ticks: usize,
last_turn_direction: enum { left, right },
```

Example behavior:

```text
If the robot has been turning left for 50 scans and the front is still blocked,
switch and try turning right.
```

## Suggested Starting State

```zig
const Mode = enum {
    drive_forward,
    avoid_left,
    avoid_right,
    stop,
};

pub const LaserRadarHandler = struct {
    allocator: Allocator,

    mode: Mode = .drive_forward,
    ticks_in_mode: usize = 0,

    front_blocked_count: usize = 0,
    front_clear_count: usize = 0,

    last_front_min: f32 = 0,
    last_left_min: f32 = 0,
    last_right_min: f32 = 0,

    previous_command: DriveCommand = .{
        .linear_x = 0,
        .angular_z = 0,
    },
};
```

## Suggested Per-Scan Flow

Every time Zig receives a `LaserScanFFISafe`:

```text
1. Validate scan data
2. Compute left/front/right minimum distances
3. Update blocked/clear counters
4. Update behavior mode
5. Produce desired DriveCommand
6. Smooth against previous_command
7. Store previous_command
8. Return DriveCommand to C++
```

## Simple First Behavior

```text
If front is clear:
    drive forward

If front is blocked:
    turn toward the side with more space

If blocked for too long:
    reverse, stop, or switch turn direction
```

## Architecture Reminder

Keep this boundary clean:

```text
C++ owns ROS:
  - subscriptions
  - publishers
  - ROS message types
  - Gazebo topics

Zig owns behavior:
  - scan interpretation
  - memory/state
  - obstacle avoidance
  - DriveCommand decision
```
