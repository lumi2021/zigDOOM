const std = @import("std");

// root imports
pub const allocator: *std.mem.Allocator = &gpalloc;

pub const video = @import("video.zig");

pub const utils = @import("utils/utils.zig");
pub const doom_src = @import("doom_src/doomsrc.zig");

var gpalloc: std.mem.Allocator = undefined;

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    gpalloc = gpa.allocator();

    // init system
    //try video.init();

    // init utils and helpers
    try utils.init();

    // init game
    try doom_src.main.dMain();
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    video.try_dispose();

    std.debug.print("!!! panic !!!\n\r", .{});
    std.debug.print("{s}\n\r", .{msg});
    if (stack_trace) |st| std.debug.dumpStackTrace(st.*);

    std.process.exit(1);
}
