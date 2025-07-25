const root = @import("root");
const std = @import("std");


var allocator: std.mem.Allocator = undefined;
pub var full_buf: [][:0]u8 = undefined;
pub var arguments: [][:0]u8 = undefined;
var lastIndexed: usize = 0;

pub fn init(alloc: std.mem.Allocator) !void {
    allocator = alloc;
    full_buf = (std.process.argsAlloc(allocator) catch unreachable);
    arguments = full_buf[1..];
}
pub fn deinit() void {
    std.process.argsFree(allocator, full_buf);
}

pub fn get_args() [][:0]u8 { return arguments; }
pub fn set_args(args: [][:0]u8) void { arguments = args; lastIndexed = 0; }

pub fn get_arg(index: usize) [:0]u8 { return arguments[index]; }

pub fn get_next() ![:0]u8 {
    lastIndexed += 1;
    if (arguments.len < lastIndexed+1) return error.IndexOutOfBounds;
    const val = arguments[lastIndexed];
    return val;
}
pub fn get_next_value() !?[:0]u8 {
    lastIndexed += 1;
    if (arguments.len < lastIndexed+1) return error.IndexOutOfBounds;
    const val = arguments[lastIndexed];
    if (val[0] != '-') {
        return val;
    }
    else return null;
}

pub fn harg(comptime arg:[]const u8) bool {
    for (0..arguments.len) |i| {
        if (std.mem.eql(u8, arguments[i], arg)) {
            lastIndexed = i;
            return true;
        }
    }
    return false;
}
// implementation of:
//     https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/m_argv.c#L41
pub fn sarg(comptime arg:[]const u8) !usize {
    for (0..arguments.len) |i| {
        if (std.mem.eql(u8, arguments[i], arg)) {
            lastIndexed = i;
            return i;
        }
    }
    return error.ArgumentNotFound;
}
pub fn sarg_starthwith(comptime char: u8) !usize {
    for (0..arguments.len) |i| {
        if (arguments[i][0] == char) {
            lastIndexed = i;
            return i;
        }
    }
    return error.ArgumentNotFound;
}

pub fn garg(comptime arg:[]const u8) ![:0]u8 { return get_arg(try sarg(arg));}
pub fn garg_starthwith(comptime char: u8) ![:0]u8 {return get_arg(try sarg_starthwith(char));}
