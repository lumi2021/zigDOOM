const std = @import("std");

// root imports
pub const allocator: *std.mem.Allocator = &gpalloc;

pub const utils = @import("utils/utils.zig");
pub const doom_src = @import("doom_src/doomsrc.zig");

// toot config
pub const show_debug_messages = true;
pub const show_log_messages = true;

var gpalloc: std.mem.Allocator = undefined;

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    gpalloc = gpa.allocator();

    // init utils and helpers
    try utils.init();

    // init game
    try doom_src.main();

}

pub inline fn print_dbg(comptime fmt: []const u8, args: anytype) void {
    comptime if (!show_debug_messages) return;
    std.debug.print(fmt, args);
}
pub inline fn print_log(comptime fmt: []const u8, args: anytype) void {
    comptime if (!show_log_messages) return;
    std.debug.print(fmt, args);
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    std.debug.print("!!! panic !!!\n\r", .{});
    std.debug.print("{s}\n\r", .{msg});
    if (stack_trace) |st| std.debug.dumpStackTrace(st.*);

    std.process.exit(1);
}
