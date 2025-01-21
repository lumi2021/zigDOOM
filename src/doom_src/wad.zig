const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const dstc = root.doom_src;
const resourses = dstc.resources;

const alloc = root.allocator;

var numlumps: i32 = 0;
var lumpinfo: []LumpInfo = undefined;

var reloadlump: i32 = undefined;
var reloadname: ?[]u8 = undefined;

const FileLump = extern struct {
    filepos: i32,
    size: i32,
    name: [8]u8,
};
const LumpInfo = struct {
    name: [8]u8,
    handle: ?std.fs.File,
    position: i32,
    size: i32,
};
const WadInfo = extern struct {
    identification: [4]u8,
    numlumps: i32,
    infotableofs: i32,
};

const FileLumpList = std.ArrayList(FileLump);

pub fn init_wads() !void {

    const filepaths = dstc.resources.wad_files;

    for (filepaths.items) |i| {
        add_file(i)
            catch |err| std.debug.print("Error: {s}\n", .{@errorName(err)});
    }
}

fn add_file(filename: []u8) !void {
    var fnaame = filename;

    // open the file and add to directory

    // handle reload indicator
    if (filename[0] == '~') {
        fnaame = filename[1..];
        reloadname = fnaame;
        reloadlump = numlumps;
    }

    const p: ?[]u8 = std.fs.realpathAlloc(alloc.*, fnaame) catch null;
    if (p) |path| {

        const handle = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });

        std.debug.print("Adding file {s}\n", .{path});

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

            std.debug.print("{s}: {} lumps\n", .{header.identification, header.numlumps});

            const lumps = try alloc.alloc(FileLump, @intCast(header.numlumps));
            const lumpsbuf = @as([*]u8, @ptrCast(@alignCast(lumps.ptr)))[0..(lumps.len * @sizeOf(FileLump))];

            try handle.seekTo(@intCast(header.infotableofs));
            _ = try handle.read(lumpsbuf);
            
            std.debug.print("Parsed {} lumps\n", .{lumps.len});

            try fileInfo.appendSlice(lumps);
        }

        // fill in lumpinfo
        lumpinfo = try alloc.realloc(lumpinfo, fileInfo.items.len);
        const savehanlde: ?std.fs.File = if (reloadname == null) null else handle;

        for (0..fileInfo.items.len, fileInfo.items) |i, lump| {

            std.debug.print("{s} ", .{lump.name});

            lumpinfo[i].handle = savehanlde;
            lumpinfo[i].position = lump.filepos;
            lumpinfo[i].size = lump.size;
            @memcpy(&lumpinfo[i].name, &lump.name);

        }

    }
    else {
        std.debug.print("Cannot open file {s}\n", .{filename});
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


inline fn force_endianness(T: type, value: *T) void {
    comptime if (builtin.cpu.arch.endian() == .big) {
        std.mem.byteSwapAllFields(T, value);
    };
}
