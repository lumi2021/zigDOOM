const std = @import("std");
const root = @import("root");
const video = root.rendering.video;


const c = @cImport({
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL3/SDL.h");
});

var win: *c.struct_SDL_Window = undefined;
var renderer: *c.struct_SDL_Renderer = undefined;
var texture: *c.struct_SDL_Texture = undefined;
var color_indexes: [][3]u8 = undefined;

pub fn init_graphics() !void {

    color_indexes = try root.zone.gpa.alloc([3]u8, 256);

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) @panic("SDL3 failed to initialize!");

    win = c.SDL_CreateWindow(
        "zigDOOM",
        video.screen_width,
        video.screen_height,
        c.SDL_WINDOW_RESIZABLE
    ) orelse @panic("SDL3 failed to create window!");

    renderer = c.SDL_CreateRenderer(win, null)
        orelse @panic("SDL3 failed to create renderer!");

    texture = c.SDL_CreateTexture(
        renderer, 
        c.SDL_PIXELFORMAT_RGB24,
        c.SDL_TEXTUREACCESS_STREAMING,
        video.screen_width,
        video.screen_height,
    );

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

pub fn set_pallete(pallete: [][3]u8) void {
    @memcpy(color_indexes, pallete);
}

pub fn update_window() void {
    const screen_data: *[video.screen_width * video.screen_height]u8 = video.screens[0];

    var pixels: [*]u8 = undefined;
    var pitch: c_int = 0;

    _ = c.SDL_LockTexture(texture, null, @ptrCast(&pixels), &pitch);
    for (0..screen_data.len) |i| {

        const col = color_indexes[screen_data[i]];

        pixels[i * 3 + 0] = col[0];
        pixels[i * 3 + 1] = col[1];
        pixels[i * 3 + 2] = col[2];

    }
    c.SDL_UnlockTexture(texture);

    _ = c.SDL_RenderTexture(renderer, texture, null, null);
    _ = c.SDL_RenderPresent(renderer);
}
