const std = @import("std");
const builtin = @import("builtin");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub const allocator: std.mem.Allocator = switch (builtin.mode) {
    .Debug, .ReleaseSafe => debug_allocator.allocator(),
    else => std.heap.smp_allocator,
};

pub const game_state = @import("game_state.zig");
pub const info = @import("info.zig");

pub const resources = @import("resources/resources.zig");
pub const rendering = @import("rendering/rendering.zig");
pub const play = @import("play/play.zig");
pub const interface = @import("interface/interface.zig");
pub const system = @import("system/system.zig");
pub const gameloop = @import("gameloop.zig");

pub const zone = @import("zone.zig");

pub const utils = .{
    .args_handler = @import("utils/args_handler.zig"),
};


pub fn main() !void {
    defer if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) { _ = debug_allocator.deinit(); };
    try utils.args_handler.init(allocator);
    defer utils.args_handler.deinit();

    find_response_fine() catch |err| @panic(@errorName(err));

    identify_version();

    // TODO handle flag -nomonsters
    // TODO handle flag -respawn
    // TODO handle flag -fast
    // TODO handle flag -devparm
    // TODO handle flag -altdeath
    // TODO handle flag -deathmatch
    // TODO handle flag -cdrom
    // TODO handle flag -turbo

    if (utils.args_handler.harg("-file")) {
        game_state.modified_game = true;

        while (utils.args_handler.get_next_value() catch null) |x| {
            resources.add_file(x);
        }
    }

    // TODO handle flag -playdemo
    // TODO handle flag -timedemo
    // TODO handle flag -skill
    // TODO handle flag -episode
    // TODO handle flag -warp

    // Initialize game state
    game_state.skill_level = .medium;
    game_state.start_episode = 1;
    game_state.start_map = 1;

    // TODO handle flag -skill
    // TODO handle flag -episode
    // TODO handle flag -timer
    // TODO handle flag -avg
    // TODO handle flag -warp

    // Initialize systems
    std.log.info("V_Init: allocate screens.\n", .{});
    try @import("video/video.zig").init();

    // This don't do shit as we are using zig's memory allocator
    std.log.info("Z_Init: Init zone memory allocation daemon. \n", .{});

    std.log.info("W_Init: Init WADfiles.\n", .{});
    try resources.wad.init();

    // check for -file in shareware
    // TODO https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L1025-L1047

    if (game_state.modified_game) {
        std.debug.print(
        \\===========================================================================
	    \\ ATTENTION:  This version of DOOM has been modified.  If you would like to
	    \\get a copy of the original game, call 1-800-IDGAMES or see the readme file.
	    \\        You will not receive technical support for modified games.
	    \\                       press enter to continue
	    \\===========================================================================
        \\
        , .{});
        
        if (builtin.mode != .Debug) _ = try std.io.getStdIn().reader().readByte();
    }

    switch (game_state.gamemode) {
        .shareware,
        .indetermined => {
            std.debug.print(
            \\===========================================================================
            \\                                Shareware!
            \\===========================================================================
            \\
            , .{});
        },

        .commecial,
        .retail,
        .registered => {
            std.debug.print(
            \\===========================================================================
            \\               Commercial product - do not distribute!\n"
	        \\         Please report software piracy to the SPA: 1-800-388-PIR8\n"
            \\===========================================================================
            \\
            , .{});
        },

        // else => Ouch. 
    }

    // Initialize more systems bruh
    std.log.info("M_Init: Init miscellaneous info.\n", .{});
    try @import("menus/menu.zig").init();

    std.log.info("R_Init: Init DOOM refresh daemon - ", .{});
    try rendering.init();

    std.log.info("\nP_Init: Init Playloop state.\n", .{});
    try play.init();

    std.log.info("I_Init: Setting up machine state.\n", .{});
    // TODO ignored for now

    std.log.info("D_CheckNetGame: Checking network game status.\n", .{});
    // TODO ignored for now

    std.log.info("S_Init: Setting up sound.\n", .{});
    // TODO ignored for now

    std.log.info("HU_Init: Setting up heads up display.\n", .{});
    try interface.init();

    std.log.info("ST_Init: Init status bar.\n", .{});
    try interface.status_bar.init();

    
    try gameloop.gameloop();
    unreachable;

}

fn find_response_fine() !void {

    const found_path = utils.args_handler.garg_starthwith('@') catch null;

    if (found_path) |path| {
        const p = try std.fs.realpathAlloc(allocator, path);
        std.log.debug("path found: {s}\n", .{p});

        const handle = try std.fs.openFileAbsolute(p, .{ .mode = .read_only });
        const size: usize = switch (builtin.os.tag) {
            .linux => (try handle.metadata()).inner.size(),
            else => @panic("OS not supported!"),
        };

        std.log.debug("{s} ({} bytes)\n", .{ p, size });

        std.log.debug("allocating args file...\n", .{});
        const file = try handle.readToEndAlloc(allocator, size);
        
        var argslist = std.ArrayList([:0]u8).init(allocator);

        std.log.debug("spliting args file...\n", .{});
        var args_iterator = std.mem.splitSequence(u8, file, " ");
        while (args_iterator.next()) |arg| try argslist.append(@constCast(@ptrCast(arg)));

        std.log.debug("replacing args...\n", .{});
        utils.args_handler.set_args(try argslist.toOwnedSlice());
    }
}

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L563
// too much effort for unecessary things :p
fn identify_version() void {}


pub const std_options: std.Options = .{ .logFn = logFn, };

fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {

    _ = scope;

    switch (message_level) {

        .info,
        .err => std.io.getStdOut().writer().print(format, args) catch unreachable,
        .debug,
        .warn => if (builtin.mode != .Debug) std.io.getStdErr().writer().print(format, args) catch unreachable,

    }
}
