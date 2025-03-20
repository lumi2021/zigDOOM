const std = @import("std");
const root = @import("root");
const enums = root.doom_src.enums;

const alloc = root.allocator;

const zoneid = 0x1d4a11;
const minfragment = 64;

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
    tag: enums.ZoneTags,
    id: i32,

    next: *Memblock,
    prev: *Memblock
};

pub fn init() !void {
    var block: *Memblock = undefined;
    
    const buf = InitZoneBase();
    const size: i32 = @intCast(buf.len);

    mainzone = @ptrCast(@alignCast(buf));
    mainzone.size = size;

    block = @ptrFromInt(@intFromPtr(mainzone) + @sizeOf(Memzone));
    mainzone.blocklist.prev = block;
    mainzone.blocklist.next = block;

    mainzone.blocklist.user = @ptrCast(&mainzone);
    mainzone.blocklist.tag = .static;
    mainzone.rover = block;

    block.next = &mainzone.blocklist;
    block.prev = block.next;
    block.user = null;

    block.size = mainzone.size - @sizeOf(Memzone);
}

// Implementation of
//    https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/i_system.c#L76
pub fn InitZoneBase() []u8 {
    const size: usize = mb_used * 1024 * 1024;
    root.print_dbg("Allocating {} MiB\n", .{mb_used});
    const buffer = alloc.alloc(u8, size) catch unreachable;
    std.debug.print("heap: {x}..{x}, {} bytes\n", .{@intFromPtr(buffer.ptr), @intFromPtr(buffer.ptr) + size, size});
    return buffer;
}

// Implementation of
//    https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/z_zone.c#L184
pub fn malloc(size: anytype, tag: enums.ZoneTags, user: ?**anyopaque) [*]u8 {
    // fix to the weird zig alignment shit
    const alig: i32 = @alignOf(Memblock) - 1;
    const _size: i32 = ((@as(i32, @intCast(size)) + alig) & ~alig)
    + @sizeOf(Memblock); // account for size of block header

    root.print_log("allocating {} bytes ({} requested)...\n", .{_size, size});

    // scan through the block list,
    // looking for the first free block
    // of sufficient size,
    // throwing out any purgable blocks along the way.

    // if there is a free block behind the rover,
    //  back up over them
    var base = mainzone.rover;
    if (base.prev.user == null) base = base.prev;

    var rover = base;
    const start = rover.prev;

    while (true) {
        if (rover == start) {
            std.debug.print("Failed to allocate {} bytes, no free memory available!\n", .{_size});
            @panic("Memory Allocation Fault");
        }

        if (rover.user != null) {
            if (@intFromEnum(rover.tag) < @intFromEnum(enums.ZoneTags.purgelevel)) {
                // hit a block that can't be purged,
		        //  so move base past it
                rover = rover.next;
                base = rover;
            } else {
                // free the rover block (adding the size to base)
                base = base.prev;
                free_block(rover);
                base = base.next;
                rover = base.next;
            }
        } else {
            rover = rover.next;
        }

        if (base.user == null or base.size < _size) break;
    }

    const extra = base.size - _size;

    if (extra > minfragment) {
        // there will be a free fragment after the allocated block
        const newblock: *Memblock = @ptrFromInt(@intFromPtr(base) + @as(usize, @intCast(_size)));
        newblock.size = extra;

        // NULL indicates free block.
        newblock.user = null;
        newblock.tag = @enumFromInt(0);
        newblock.prev = base;
        newblock.next = base.next;
        newblock.next.prev = newblock;

        base.next = newblock;
        base.size = _size;
    }

    if (user != null) {
        base.user = user.?;
        user.?.* = @ptrFromInt(@intFromPtr(base) + @sizeOf(Memblock));
    } else {
        if (@intFromEnum(tag) > @intFromEnum(enums.ZoneTags.purgelevel))
            @panic("A user is required for purgable blocks");
        
        // mark as in use, but unowned
        base.user = @ptrFromInt(@alignOf(usize));		
    }

    base.tag = tag;

    // next allocation will start looking here
    mainzone.rover = base.next;

    base.id = zoneid;

    return @ptrFromInt(@intFromPtr(base) + @sizeOf(Memblock));
}
// some wrappers because for god's sake C memory management is so poor
pub inline fn malloc_buf(comptime T: type, len: anytype, tag: enums.ZoneTags, user: ?**anyopaque) [*]T {
    const size_in_bytes = len * @sizeOf(T);
    const buf = malloc(size_in_bytes, tag, user);
    return @ptrCast(@alignCast(buf));
}
pub inline fn malloc_slice(comptime T: type, len: anytype, tag: enums.ZoneTags, user: ?**anyopaque) []T {
    return malloc_buf(T, len, tag, user)[0..@intCast(len)];
}
pub inline fn malloc_obj(comptime T: type, tag: enums.ZoneTags, user: ?**anyopaque) *T {
    const buf = malloc(@sizeOf(T), tag, user);
    return @ptrCast(@alignCast(buf));
}

// Implementation of
//    https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/z_zone.c#L122
pub fn free(ptr: anytype) void {
    if (@typeInfo(@TypeOf(ptr)) != .pointer) @compileError("value must be a pointer!");

    const block: *Memblock = @ptrFromInt(@intFromPtr(ptr) - @sizeOf(Memblock));
    if (block.id != zoneid) @panic("Freed a block without ZONEID");
    free_block(block);
}
fn free_block(_block: *Memblock) void {

    var block = _block;
    //std.debug.print("freeing {} bytes... ({s})\n", .{block.size, @tagName(block.tag)});

    block.user = null;
    block.tag = @enumFromInt(0);
    block.id = 0;

    var other = block.prev;

    if (other.user == null) {
        other.size += block.size;
        other.next = block.next;
        other.next.prev = other;

        if (block == mainzone.rover)
            mainzone.rover = other;
        
        block = other;
    }

    other = block.next;
    if (other.user == null) {
        block.size += other.size;
        block.next = other.next;
        block.next.prev = block;

        if (other == mainzone.rover)
            mainzone.rover = block;
    }

}
