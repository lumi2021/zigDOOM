const root = @import("root");
const std = @import("std");

pub const wad = @import("wad.zig");

const allocator = root.allocator;

pub var wad_files: std.ArrayListUnmanaged([]const u8) = .empty;

pub fn add_file(path: []u8) void {
    wad_files.append(allocator, path)
        catch |err| std.debug.print("Error: {s}\n", .{@errorName(err)});
}
