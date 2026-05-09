//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const io = std.Io.Threaded.global_single_threaded.io();
const allocator = std.heap.c_allocator;

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

pub const LaserRadarHandler = struct {
    const Self = @This();
    const Allocator = std.mem.Allocator;

    allocator: Allocator,

    pub fn init() !Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        _ = self;
    }
};

fn printToStdout(comptime size: usize, input: []const u8) !void {
    var buf: [size]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const writer = &stdout_writer.interface;

    writer.writeAll(input) catch return;
    writer.writeAll("\n") catch return;

    writer.flush() catch return;
}

/// This allocates space for the handler and returns the pointer to it in u64
export fn spawnHandler() callconv(.c) u64 {
    const handler_ptr = allocator.create(LaserRadarHandler) catch unreachable;
    handler_ptr.* = LaserRadarHandler.init() catch unreachable;

    const handler_ptr_in_int = @intFromPtr(handler_ptr);
    return handler_ptr_in_int;
}

export fn handleMessage(handler_ptr_in_int: u64, msg: LaserScanFFISafe) callconv(.c) void {
    _ = msg;

    // I don't want to allocate anything here so I'll reserve a slice here on stack
    const print_buf_size: comptime_int = 1028 * 4;
    var buf: [print_buf_size]u8 = undefined;
    const formatted_buf = std.fmt.bufPrint(&buf, "handler ptr in int: {d}", .{handler_ptr_in_int}) catch unreachable;
    printToStdout(print_buf_size, formatted_buf) catch unreachable;
}
