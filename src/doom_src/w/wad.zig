const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const dstc = root.doom_src;
const resourses = dstc.resources;
const enums = dstc.enums;

const alloc = root.allocator;

const FileLumpList = std.ArrayList(FileLump);

var lumpinfo: []LumpInfo = undefined;

var lumpCache: []?[]u8 = undefined;

const FileLump = extern struct {
    filepos: i32,
    size: i32,
    name: [8]u8,
};
const LumpInfo = struct {
    name: [8]u8,
    name32: [2]u32, // not in the src! //
    handle: ?std.fs.File,
    position: i32,
    size: i32,
};
const WadInfo = extern struct {
    identification: [4]u8,
    numlumps: i32,
    infotableofs: i32,
};

const force_endianness = root.utils.force_endianness;

pub fn init_wads() !void {

    const filepaths = dstc.resources.wad_files;

    for (filepaths.items) |i| {
        add_file(i)
            catch |err| std.debug.print("Error: {s}\n", .{@errorName(err)});
    }

    lumpCache = try alloc.alloc(?[]u8, lumpinfo.len);
    for (0.., lumpCache) |i, _| lumpCache[i] = null;

    root.print_dbg("{} lumps loaded!\n", .{lumpinfo.len});
}

fn add_file(filename: []u8) !void {
    // open the file and add to directory

    const fnaame = filename;

    // handle reload indicator
    // TODO reload indicator

    const p: ?[]u8 = std.fs.realpathAlloc(alloc.*, fnaame) catch null;
    if (p) |path| {

        const handle = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });

        root.print_log("Adding file {s}\n", .{path});

        var fileInfo = FileLumpList.init(alloc.*);

        if (!std.ascii.eqlIgnoreCase(filename[(filename.len - 3)..], "wad")) {
            // single lump file
            var singleInfo: FileLump = undefined;

            singleInfo.filepos = 0;
            singleInfo.size = @intCast((try handle.stat()).size);
            extract_file_base(filename, &singleInfo.name);

            try fileInfo.append(singleInfo);
        } else {
            // WAD file

            var headerbuf: [@sizeOf(WadInfo)]u8 = undefined;
            _ = try handle.read(&headerbuf);

            const header: *WadInfo = @ptrCast(@alignCast(&headerbuf));

            if (!std.mem.eql(u8, &header.identification, "IWAD") and
                !std.mem.eql(u8, &header.identification, "PWAD")) {
                return error.UnknownWADMagic;
            }

            force_endianness(i32, &header.infotableofs);
            force_endianness(i32,&header.infotableofs);

            root.print_dbg("{s}: {} lumps\n", .{header.identification, header.numlumps});

            const lumps = try alloc.alloc(FileLump, @intCast(header.numlumps));
            const lumpsbuf = @as([*]u8, @ptrCast(@alignCast(lumps.ptr)))[0..(lumps.len * @sizeOf(FileLump))];

            try handle.seekTo(@intCast(header.infotableofs));
            _ = try handle.read(lumpsbuf);
            
            root.print_dbg("Parsed {} lumps\n", .{lumps.len});

            try fileInfo.appendSlice(lumps);
        }

        // fill in lumpinfo
        lumpinfo = try alloc.realloc(lumpinfo, fileInfo.items.len);
        const savehanlde: ?std.fs.File = handle; // FIXME reload indicator

        for (0..fileInfo.items.len, fileInfo.items) |i, lump| {

            lumpinfo[i].handle = savehanlde;
            lumpinfo[i].position = lump.filepos;
            lumpinfo[i].size = lump.size;
            @memcpy(&lumpinfo[i].name, &lump.name);

            lumpinfo[i].name32[0] = @bitCast(lump.name[0..4].*);
            lumpinfo[i].name32[1] = @bitCast(lump.name[4..8].*);

        }

        // if (reloadname == null) handle.close(); // FIXME reload indicator
    }
    else {
        root.print_log("Cannot open file {s}\n", .{filename});
        return error.FileNotFound;
    }

}

fn extract_file_base(path: []u8, dest: []u8) void {

    var start_index = path.len - 1;
    var src: []u8 = path[start_index..];

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


pub fn cache_lump_name(name: []const u8, tag: enums.ZoneTags) []u8 {
    return cache_lump_num(get_num_for_name(name), tag);
}
pub fn cache_lump_num(index: i32, tag: enums.ZoneTags) []u8 {
    const u_idx: usize = @intCast(@as(u32, @bitCast(index)));

    if (index > lumpinfo.len) @panic("index out of bounds!");

    if (lumpCache[u_idx] == null) {
        const size = lumpinfo[u_idx].size;

        const ptr = dstc.zone.malloc(
            size,
            tag,
            @ptrCast(&lumpCache[u_idx])
        );
        const buf: []u8 = @as([*]u8, @ptrCast(ptr))[0..@intCast(size)];
        lumpCache[u_idx] = buf;

        read_lump(index, buf);
    }

    return lumpCache[u_idx].?;
}

pub fn read_lump(index: i32, dest: []u8) void {
    const u_idx: usize = @intCast(@as(u32, @bitCast(index)));

    if (index > lumpinfo.len) @panic("index out of bounds!");

    const l = lumpinfo[u_idx];

    if (l.handle) |handle| {

        handle.seekTo(@intCast(l.position)) catch unreachable;
        _ = handle.readAll(dest) catch unreachable;

    } else { @panic("Cannot access data source file!"); }
}
pub fn lump_length(index: i32) i32 {
    if (index > lumpinfo.len) @panic("index out of bounds!");
    return lumpinfo[@intCast(@as(u32, @bitCast(index)))].size;
}


pub fn get_num_for_name(name: []const u8) i32 {
    return check_num_for_name(name);
}
pub fn check_num_for_name(name: []const u8) i32 {
    
    var name8: [9]u8 = std.mem.zeroes([9]u8);
    _ = std.ascii.upperString(&name8, name);

    const v1: u32 = @bitCast(name8[0..4].*);
    const v2: u32 = @bitCast(name8[4..8].*);

    var i: i32 = @intCast(lumpinfo.len - 1);

    // scan backwards so patch lump files take precedence
    while (i >= 0) : (i -= 1) {
        if (lumpinfo[@intCast(i)].name32[0] == v1
        and lumpinfo[@intCast(i)].name32[1] == v2)
            return i;
    }

    // TFB. Not found.
    return -1;

}

