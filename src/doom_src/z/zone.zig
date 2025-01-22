const std = @import("std");
const root = @import("root");

const alloc = root.allocator;

const zoneid = 0x1d4a11;

const tag_static = 1;
const tag_sound = 2;
const tag_music = 3;
const tag_david = 4; // anything else Dave wants static
const tag_level = 50;
const tag_levspec = 51;
const tag_purgelevel = 100;
const tag_cache = 101;

const mb_used: usize = 6;
var mainzone: *Memzone = undefined;

pub const Memzone = struct {
    size: i32,
    blocklist: Memblock,
    rover: *Memblock
};
pub const Memblock = struct { 
    size: i32,
    user: ?**anyopaque,
    tag: i32,
    id: i32,

    next: *Memblock,
    prev: *Memblock
};

pub fn init() !void {

    var block: *Memblock = undefined;
    const size: i32 = 0;
    
    const buf = InitZoneBase();

    mainzone = @ptrCast(@alignCast(buf));
    mainzone.size = size;

    block = @ptrFromInt(@intFromPtr(mainzone) + @sizeOf(Memzone));
    mainzone.blocklist.prev = block;
    mainzone.blocklist.next = block;

    mainzone.blocklist.user = @ptrCast(&mainzone);
    mainzone.blocklist.tag = tag_static;
    mainzone.rover = block;

    block.prev = &mainzone.blocklist;
    block.next = &mainzone.blocklist;
    block.user = null;

    block.size = mainzone.size - @sizeOf(Memzone);
}

// Implementation of
//    https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/i_system.c#L76
pub fn InitZoneBase() []u8 {
    const size: usize = mb_used * 1024 * 1024;
    root.print_dbg("Allocating {} MiB ({} bytes)\n", .{mb_used, size});
    return alloc.alloc(u8, size) catch unreachable;
}
