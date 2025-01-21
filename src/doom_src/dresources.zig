const root = @import("root");
const std = @import("std");

const alloc = root.allocator;

const WadPathList = std.ArrayList([]u8);
pub var wad_files: WadPathList = undefined;

pub fn init() void {
    wad_files = WadPathList.init(alloc.*);
}

pub fn dAdd_file(path: []u8) void {
    wad_files.append(path)
        catch |err| std.debug.print("Error: {s}\n", .{@errorName(err)});
}