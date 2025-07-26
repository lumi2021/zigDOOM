const std = @import("std");
const root = @import("root");

const c = @cImport({
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL3/SDL.h");
});

var win: *c.struct_SDL_Window = undefined;
var renderer: *c.struct_SDL_Renderer = undefined;

pub fn init_graphics() !void {

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) @panic("SDL3 failed to initialize!");

    win = c.SDL_CreateWindow(
        "zigDOOM",
        640, 400,
        c.SDL_WINDOW_RESIZABLE
    ) orelse @panic("SDL3 failed to create window!");

    renderer = c.SDL_CreateRenderer(win, null)
        orelse @panic("SDL3 failed to create renderer!");

}

pub fn start_tic() void {
    // Nothing to do with SDL
}

pub fn translate_events(event: *?root.Event) bool {

    var sdle: c.SDL_Event = undefined;
    const res = c.SDL_PollEvent(&sdle);

    switch (sdle.type) {
        c.SDL_EVENT_QUIT => root.gameloop.running = false,

        c.SDL_EVENT_MOUSE_MOTION => {
            event.* = .{ .mouse = .{ sdle.motion.xrel, sdle.motion.yrel }};
        },

        
        else => {}
    }
    
    return res;
}

pub fn update_window() void {
    _ = c.SDL_RenderPresent(renderer);
}
