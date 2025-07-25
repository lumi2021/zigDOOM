const builtin = @import("builtin");
const std = @import("std");

pub const args_handler = @import("args_handler.zig");

pub inline fn force_endianness(value: anytype) @TypeOf(value)  {
    if (@typeInfo(@TypeOf(value)) != .@"int") @compileError("value is not of type integer!");

    if (comptime builtin.cpu.arch.endian() == .big)
        return std.mem.byteSwapAllFields(@TypeOf(value), value)
    else return value;
}

// initialize all util libraries that need some initializing
pub fn init() !void {
    try args_handler.init();
}
