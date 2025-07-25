const root = @import("root");
const std = @import("std");
const fs = std.fs;

const zone = root.zone;

pub var lumpinfo: []LumpInfo = undefined;
var lumpCache: []?[]u8 = undefined;

const FileLump = extern struct {
    filepos: i32,
    size: i32,
    name: [8]u8,
};
const LumpInfo = struct {
    name: extern union {
        str: [8:0]u8,
        int: u64,  // not in the src! //
    },
    handle: ?std.fs.File,
    position: usize,
    size: usize,
};
const WadInfo = extern struct {
    identification: [4]u8,
    numlumps: i32,
    infotableofs: i32,
};

pub fn init() !void {

    const file_paths = try@import("resources.zig").wad_files.toOwnedSlice(zone.gpa);
    defer zone.gpa.free(file_paths);

    var lumpinfo_temp: std.ArrayList(LumpInfo) = .init(zone.get(.static));

    for (file_paths) |i| {
        add_file(i, &lumpinfo_temp) catch |err| std.log.err("Error: {s}", .{@errorName(err)});
    }
    std.log.info("aaaaa {}\n", .{ lumpinfo_temp.items.len });
    lumpinfo = try lumpinfo_temp.toOwnedSlice();

    lumpCache = try zone.get(.static).alloc(?[]u8, lumpinfo.len);
    @memset(lumpCache, null);

    std.log.info("{} lumps loaded!\n", .{lumpinfo.len});

}

fn add_file(filename: []const u8, lump_info: *std.ArrayList(LumpInfo)) !void {
    
    // handle reload indicator
    // TODO reload indicator

    const handle = fs.cwd().openFile(filename, .{ .mode = .read_only })
    catch |err| {
        std.log.err("Cannot open file {s} : {s}\n", .{filename, @errorName(err)});
        return error.FileNotFound;
    };

    std.log.info("Adding file {s}\n", .{filename});

    var fileinfo: std.ArrayListUnmanaged(FileLump) = .empty;
    defer fileinfo.deinit(zone.gpa);

    if (!std.ascii.eqlIgnoreCase(filename[filename.len - 3..], "wad")) {
        // Single lump file

        var singleinfo: FileLump = undefined;

        singleinfo.filepos = 0;
        singleinfo.size = @intCast((try handle.stat()).size);
        extract_file_base(filename, &singleinfo.name);

        try fileinfo.append(zone.gpa, singleinfo);
    } else {
        // WAD file

        var header: WadInfo = undefined;
        _ = try handle.read(std.mem.asBytes(&header));

        if (!std.mem.eql(u8, &header.identification, "IWAD")
        and !std.mem.eql(u8, &header.identification, "PWAD")) {
            return error.UnknownWadMagic;
        }

        std.log.debug("{s}: {} lumps\n", .{header.identification, header.numlumps});

        const lumps = try zone.gpa.alloc(FileLump, @intCast(header.numlumps));
        defer zone.gpa.free(lumps);

        try handle.seekTo(@intCast(header.infotableofs));
        _ = try handle.read(std.mem.sliceAsBytes(lumps));

        for (lumps) |i| try fileinfo.append(zone.gpa, i);

        std.log.debug("parsed {} lumps\n", .{lumps.len});

    }

    // fill in lump info
    const savehandle: ?fs.File = handle; // FIXME reload indicator

    for (fileinfo.items) |lump| {
        const nlump = try lump_info.addOne();
        nlump.handle = savehandle;
        nlump.position = @intCast(lump.filepos);
        nlump.size = @intCast(lump.size);
        nlump.name.int = 0;
        @memcpy(&nlump.name.str, &lump.name);
    }

    // if (reloadname == null) handle.close(); // FIXME reload indicator
}

fn extract_file_base(path: []const u8, dest: []u8) void {

    var start_index = path.len - 1;
    var src: []const u8 = path[start_index..];

    while (!std.mem.eql(u8, src, path)
    and path[start_index-1] != '\\'
    and path[start_index-1] != '/') {
        start_index -= 1;
        src = path[start_index..];
    }

    @memset(dest, 0);

    var idx: u32 = 0;
    while (src[idx] != 0 and src[idx] != '.') {
        dest[idx] = std.ascii.toUpper(src[idx]);
        idx += 1;
    }
}


pub fn cache_lump_name(name: []const u8, tag: zone.ZoneTags) []u8 {
    return cache_lump_num(get_num_for_name(name), tag);
}
pub fn cache_lump_num(index: usize, tag: zone.ZoneTags) []u8 {
    if (index > lumpinfo.len) std.debug.panic("index {} out of bounds!", .{ index });

    if (lumpCache[index] == null) {
        const size = lumpinfo[index].size;

        const buf = zone.get(tag).alloc(u8, size) catch @panic("OOM");
        lumpCache[index] = buf;

        read_lump(index, buf);
    }

    return lumpCache[index].?;
}

pub fn read_lump(index: usize, dest: []u8) void {
    if (index > lumpinfo.len) @panic("index out of bounds!");

    const l = lumpinfo[index];

    if (l.handle) |handle| {

        handle.seekTo(@intCast(l.position)) catch unreachable;
        _ = handle.readAll(dest[0..l.size]) catch unreachable;

    } else { @panic("Cannot access data source file!"); }
}
pub fn lump_length(index: usize) usize {
    if (index > lumpinfo.len) @panic("index out of bounds!");
    return lumpinfo[index].size;
}


pub fn get_num_for_name(name: []const u8) usize {
    return check_num_for_name(name)
        orelse std.debug.panic("Lump with name \"{s}\" not found!", .{ name });
}
pub fn check_num_for_name(name: []const u8) ?usize {
    
    var name8: [9]u8 = std.mem.zeroes([9]u8);
    _ = std.ascii.upperString(&name8, name);

    const n: u64 = @bitCast(name8[0..8].*);

    var i: isize = @as(isize, @bitCast(lumpinfo.len)) - 1;

    // scan backwards so patch lump files take precedence
    while (i >= 0) : (i -= 1) {
        if (lumpinfo[@intCast(i)].name.int == n) return @bitCast(i);
    }

    // TFB. Not found.
    return null;
}
