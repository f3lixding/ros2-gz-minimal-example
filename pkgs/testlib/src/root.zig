//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const io = std.Io.Threaded.global_single_threaded.io();

export fn printToStdout(input: [*:0]const u8) callconv(.c) void {
    var buf: [1028]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const writer = &stdout_writer.interface;

    const converted_input = std.mem.span(input);

    writer.writeAll(converted_input) catch return;
    writer.writeAll("\n") catch return;
    writer.flush() catch return;
}
