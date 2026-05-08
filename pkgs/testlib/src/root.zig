//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const io = std.Io.Threaded.global_single_threaded.io();

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

export fn printToStdout(input: [*:0]const u8) callconv(.c) void {
    var buf: [1028]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const writer = &stdout_writer.interface;

    const converted_input = std.mem.span(input);

    writer.writeAll(converted_input) catch return;
    writer.writeAll("\n") catch return;
    writer.flush() catch return;
}

export fn handleMessage(msg: LaserScanFFISafe) callconv(.c) void {
    _ = msg;
}
