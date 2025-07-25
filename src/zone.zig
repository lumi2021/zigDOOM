// This resource is a little tricky because i want to emulate the
// doom allocator, that has systems to free old memory on demand.
// Instead, i implement a allocator singleton and use lots of arenas
// for the different tags.

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const gpa = @import("root").allocator;
var arenas: std.AutoArrayHashMapUnmanaged(ZoneTags, ArenaAllocator) = .empty;

pub fn init() !void {
    // it will initialize arenas for the main tags.
    // others (after purgelevel) must be created on
    // demmand.

    arenas.put(gpa, .static, .init(gpa));
    arenas.put(gpa, .sound, .init(gpa));
    arenas.put(gpa, .music, .init(gpa));
    arenas.put(gpa, .david, .init(gpa));
    arenas.put(gpa, .level, .init(gpa));
    arenas.put(gpa, .levspec, .init(gpa));
    arenas.put(gpa, .levspec, .init(gpa));
}
pub fn deinit() void {
    for (arenas.values()) |i| {
        i.deinit();
    }
    arenas.deinit(gpa);
}

pub fn get(tag: ZoneTags) Allocator {
    const arena = arenas.getOrPut(gpa, tag) catch @panic("OOM");
    if (!arena.found_existing) arena.value_ptr.* = .init(gpa);
    return arena.value_ptr.allocator();
}

pub const ZoneTags = enum(usize) {
    static = 1,
    sound = 2,
    music = 3,
    david = 4, // anything else Dave wants static

    level = 50,
    levspec = 51,

    purgelevel = 100,
    cache = 101,
    _
};
