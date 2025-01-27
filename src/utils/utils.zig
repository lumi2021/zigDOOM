const builtin = @import("builtin");
const std = @import("std");

pub const args_handler = @import("args_handler.zig");

pub inline fn force_endianness(T: type, value: *T) void {
    comptime if (builtin.cpu.arch.endian() == .big) {
        std.mem.byteSwapAllFields(T, value);
    };
}

// initialize all util libraries that need some initializing
pub fn init() !void {
    try args_handler.init();
}
