const std = @import("std");
const root = @import("root");
const game = root.game;
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

    switch (game.gamestate) {
        .demoscreen => root.gameloop.pageDrawer(),
        else => {}
    }

    set_pallete(wad.cache_lump_name("PLAYPAL", .cache));
    system_video.update_window();

}
