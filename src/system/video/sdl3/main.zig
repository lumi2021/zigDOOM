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
        960, 540,
        c.SDL_WINDOW_RESIZABLE
    ) orelse @panic("SDL3 failed to create window!");

    renderer = c.SDL_CreateRenderer(win, null)
        orelse @panic("SDL3 failed to create renderer!");

}

pub fn start_tic() void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => root.gameloop.running = false,

            c.SDL_EVENT_MOUSE_MOTION => {
                std.log.info("Mouse move: x={d}, y={d}, rel_x={d}, rel_y={d}\n",
                    .{ event.motion.x, event.motion.y,
                    event.motion.xrel, event.motion.yrel });
            },
            else => {}
        }
    }

    _ = c.SDL_RenderPresent(renderer);

}