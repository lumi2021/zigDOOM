const std = @import("std");
const vaxis = @import("vaxis");
const zigimg = vaxis.zigimg;

const Cell = vaxis.Cell;

const Window = vaxis.Window;

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
    foo: u8,
};

var alloc: std.mem.Allocator = undefined;

var vx: vaxis.Vaxis = undefined;
var tty: vaxis.Tty = undefined;
var initialized: bool = false;
var disposed: bool = false;

pub fn init() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.err("memory leak", .{});
    }
    alloc = gpa.allocator();

    // Initialize a tty
    tty = try vaxis.Tty.init();
    defer tty.deinit();

    // Initialize Vaxis
    vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.anyWriter());

    var loop: vaxis.Loop(Event) = .{
        .tty = &tty,
        .vaxis = &vx,
    };
    try loop.init();

    // Start the read loop
    try loop.start();
    defer loop.stop();

    // Optionally enter the alternate screen
    try vx.enterAltScreen(tty.anyWriter());

    // Sends queries to terminal to detect certain features
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    while (true) {
        const event = loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else {}
            },

            .winsize => |ws| try vx.resize(alloc, tty.anyWriter(), ws),
            else => {},
        }

        var win = vx.window();
        win.clear();

        win.hideCursor();

        draw_frame(win);

        try vx.render(tty.anyWriter());
    }
}

pub fn try_dispose() void {
    if (!initialized or disposed) return;

    vx.deinit(alloc, tty.anyWriter());
    tty.deinit();

    disposed = true;
}

fn draw_frame(win: Window) void {
    const game_width = 640;
    const game_height = 400;

    var canvas: [game_width * game_height * 3]u8 = undefined;

    for (0..game_width) |x| {
        for (0..game_height) |y| {
            const i = (x + game_width * y) * 3;
            canvas[i + 0] = @truncate(x);
            canvas[i + 1] = @truncate(y);
            canvas[i + 2] = 0;
        }
    }

    var image = zigimg.Image{
        .width = game_width,
        .height = game_height,
        .pixels = zigimg.color.PixelStorage.initRawPixels(&canvas, .rgb24) catch unreachable,
    };

    const img = vx.transmitImage(alloc, tty.anyWriter(), &image, .rgb) catch unreachable;

    // Image size measured in cells
    const cell_size = img.cellSize(win) catch unreachable;

    const x_pix: f32 = @floatFromInt(win.screen.width_pix);
    const y_pix: f32 = @floatFromInt(win.screen.height_pix);
    const w: f32 = @floatFromInt(win.screen.width);
    const h: f32 = @floatFromInt(win.screen.height);

    const pix_per_col = x_pix / w;
    const pix_per_row = y_pix / h;

    const aspect_ratio = @as(f32, @floatFromInt(img.width)) / @as(f32, @floatFromInt(img.height));

    // Calculate the maximum allowed width and height based on window dimensions
    const max_width_cells = @max(w, @as(f32, @floatFromInt(cell_size.cols)));
    const max_height_cells = h;

    // Calculate the pixel dimensions for the max width and height
    const max_width_pix = max_width_cells * pix_per_col;
    const max_height_pix = max_height_cells * pix_per_row;

    var final_width_pix: f32 = 0;
    var final_height_pix: f32 = 0;

    // Scale according to the most limiting direction
    if (max_width_pix / aspect_ratio <= max_height_pix) {
        final_width_pix = max_width_pix;
        final_height_pix = final_width_pix / aspect_ratio;
    } else {
        final_height_pix = max_height_pix;
        final_width_pix = final_height_pix * aspect_ratio;
    }

    const final_width_cells = final_width_pix / pix_per_col;
    const final_height_cells = final_height_pix / pix_per_row;

    img.draw(win, .{ .size = .{
        .rows = @intFromFloat(final_height_cells),
        .cols = @intFromFloat(final_width_cells),
    } }) catch unreachable;
}
