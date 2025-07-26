const std = @import("std");
const root = @import("root");
const video = root.rendering.video;
const wad = root.resources.wad;

pub const system_video = @import("video/sdl3/main.zig"); // TODO switch

pub const init_graphics = system_video.init_graphics;
pub const start_tic = system_video.start_tic;

pub fn process_events() void {
    var e: ?root.Event = null;
    while (system_video.translate_events(&e)) if (e) |event| {

        if (root.menu.event_responder(event)) continue; // menu ate the event

    };
}


pub fn start_frame() void {

    // er ?

}

pub fn set_pallete(pallete: []u8) void {
    system_video.set_pallete(@as([*][3]u8, @ptrCast(@alignCast(pallete.ptr)))[0..256]);
}

pub fn display() void {

    video.draw_patch(10, 10, 0,
    std.mem.bytesAsValue(root.rendering.data.Patch, wad.cache_lump_name("M_PAUSE", .static)));

    video.draw_patch(80, 10, 0,
    std.mem.bytesAsValue(root.rendering.data.Patch, wad.cache_lump_name("M_DOOM", .static)));

    video.draw_patch(10, 30, 0,
    std.mem.bytesAsValue(root.rendering.data.Patch, wad.cache_lump_name("STFST01", .static)));

    video.draw_patch(40, 30, 0,
    std.mem.bytesAsValue(root.rendering.data.Patch, wad.cache_lump_name("STFEVL0", .static)));

    video.draw_patch(0, 100, 0,
    std.mem.bytesAsValue(root.rendering.data.Patch, wad.cache_lump_name("STBAR", .static)));

    set_pallete(wad.cache_lump_name("PLAYPAL", .cache));

    system_video.update_window();
}
