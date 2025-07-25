const std = @import("std");
const root = @import("root");

pub const data = @import("data.zig");
pub const things = @import("things.zig");

const wad = root.resources.wad;

pub fn init() !void {
    try @import("data.zig").init_data();
}

/// Implementation of:
///     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L718
pub fn texture_num_for_name(name: []const u8) usize {
    return check_texture_num_for_name(name)
    orelse std.debug.panic("R_FlatNumForName: {s} not found\n", .{name});
}

/// Implementation of:
///     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L718
pub fn check_texture_num_for_name(name: []const u8) ?usize {
       // "NoTexture" marker.
    if (name[0] == '-') return 0;

    var name8: [9]u8 = std.mem.zeroes([9]u8);
    _ = std.ascii.upperString(&name8, name);
    const n: u64 = @bitCast(name8[0..8].*);

    for (data.textures, 0..) |t, i| if (n == t.name.int) return i;
    return null;
}

/// Implementation of:
///     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L672 \
/// R_FlatNumForName \
/// Retrieval, get a flat number for a flat name.
pub fn flat_num_for_name(name: [:0]const u8) usize {
    const i = wad.check_num_for_name(name);

    if (i == null) {
        std.debug.panic("R_FlatNumForName: {s} not found\n", .{name});
    }
    return i.? - data.firstflat;
}