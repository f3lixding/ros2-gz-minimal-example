//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const io = std.Io.Threaded.global_single_threaded.io();
const allocator = std.heap.c_allocator;

const MAX_PAST_ACTION_SIZE: usize = 10;

pub const LaserScanFFISafe = extern struct {
    /// Start angle of the scan, in radians.
    /// This is the angle of the first entry in `ranges`.
    angle_min: f32,

    /// End angle of the scan, in radians.
    /// This is the angle of the last entry in `ranges`.
    angle_max: f32,

    /// Angular distance between consecutive range readings, in radians.
    /// The angle for reading `i` is: `angle_min + i * angle_increment`.
    angle_increment: f32,

    /// Time between consecutive range readings, in seconds.
    /// Useful if the scanner or robot is moving during one scan sweep.
    time_increment: f32,

    /// Time between complete scans, in seconds.
    /// This is approximately `1.0 / update_rate` for a regularly updating lidar.
    scan_time: f32,

    /// Minimum valid range reading, in meters.
    /// Values below this should be treated as invalid/too close.
    range_min: f32,

    /// Maximum valid range reading, in meters.
    /// Values above this should be treated as invalid/no return.
    range_max: f32,

    ranges: [*]const f32,

    ranges_len: usize,
};

pub const DriveCommand = extern struct {
    linear_x: f32,
    angular_z: f32,
};

/// This has the following responsibilities via receiving laser readings:
/// - Keeps track of past actions
/// - Finally, produces DriveCommand
pub const LaserRadarHandler = struct {
    const Self = @This();
    const Allocator = std.mem.Allocator;
    const Mode = enum {
        DriveForward,
        SlowDown,
        TurnLeft,
        TurnRight,
        Stop,
    };

    allocator: Allocator,
    start_idx: usize = 0,
    end_idx: usize = 0,
    past_actions: []DriveCommand = undefined,

    state: Mode = .Stop,

    pub fn init(max_size: usize) !Self {
        const buf = try allocator.alloc(DriveCommand, max_size);
        errdefer allocator.free(buf);

        @memset(buf, .{ .linear_x = 0, .angular_z = 0 });

        return .{
            .allocator = allocator,
            .past_actions = buf,
        };
    }

    pub fn deinit(self: Self) void {
        self.past_actions.deinit(self.allocator);
    }

    pub fn handleMessage(self: *Self, msg: LaserScanFFISafe) !DriveCommand {
        _ = msg;
        const last_idx = blk: {
            if (self.end_idx > 0) {
                break :blk self.end_idx - 1;
            } else {
                const wrapped = self.past_actions.len - 1;
                break :blk wrapped;
            }
        };
        const previous_action = &self.past_actions[last_idx];
        const previous_x = previous_action.linear_x;
        const next_x = previous_x + 1;
        const conclusion: DriveCommand = .{
            .linear_x = next_x,
            .angular_z = 0.0,
        };
        // --- delete later start ---
        const print_buf_size: comptime_int = 1028 * 4;
        var buf: [print_buf_size]u8 = undefined;

        const formatted_buf = try std.fmt.bufPrint(&buf, "next conclusion: {any}", .{conclusion});
        try printToStdout(print_buf_size, formatted_buf);
        // --- delete later end ---
        self.appendNextCommand(conclusion);

        return conclusion;
    }

    fn appendNextCommand(self: *Self, command: DriveCommand) void {
        self.past_actions[self.end_idx] = command;

        const buf_size = self.past_actions.len;
        const next_idx = (self.end_idx + 1) % buf_size;

        self.end_idx = next_idx;

        if (self.end_idx == self.start_idx) {
            self.start_idx = (self.start_idx + 1) % buf_size;
        }
    }
};

fn printToStdout(comptime size: usize, input: []const u8) !void {
    var buf: [size]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const writer = &stdout_writer.interface;

    try writer.writeAll(input);
    try writer.writeAll("\n");

    try writer.flush();
}

/// This allocates space for the handler and returns the pointer to it in u64
export fn spawnHandler() callconv(.c) u64 {
    const handler_ptr = allocator.create(LaserRadarHandler) catch unreachable;
    handler_ptr.* = LaserRadarHandler.init(MAX_PAST_ACTION_SIZE) catch unreachable;

    const handler_ptr_in_int = @intFromPtr(handler_ptr);
    return handler_ptr_in_int;
}

export fn handleMessage(handler_ptr_in_int: u64, msg: LaserScanFFISafe) callconv(.c) void {
    const handler_ptr = @as(*LaserRadarHandler, @ptrFromInt(handler_ptr_in_int));
    _ = handler_ptr.handleMessage(msg) catch unreachable;
}
