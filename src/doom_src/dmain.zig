const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");

const dsrc = @import("doomsrc.zig");
const enums = dsrc.enums;
const game_state = dsrc.gamestate;

const utils = root.utils;
const alloc = root.allocator;

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L796
// part of this function is ignored due of too much effort for unecessary things :p
pub fn dMain() !void {

    // initialize zig things
    try dsrc.zig_init();

    find_response_fine() catch |err| @panic(@errorName(err));
    // not fully implemented
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

        while (utils.args_handler.get_next_value() catch null) |x|
            dsrc.resources.dAdd_file(x);
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
    std.debug.print("V_Init: allocate screens.\n", .{});
    try dsrc.sys.video.video_init();

    std.debug.print("M_LoadDefaults: Load system defaults.\n", .{});
    try dsrc.sys.misc.load_defaults();

    std.debug.print("Z_Init: Init zone memory allocation daemon. \n", .{});
    try dsrc.sys.zone.init();

    std.debug.print("W_Init: Init WADfiles.\n", .{});
    try dsrc.wad.init_wads();

    // to make sure nothing goes wrong
    std.debug.print("dmain.zig ends here!\n", .{});
}

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L722
fn find_response_fine() !void {

    const found_path = utils.args_handler.garg_starthwith('@') catch null;

    if (found_path) |path| {
        const p = try std.fs.realpathAlloc(alloc.*, path);
        std.debug.print("path found: {s}\n", .{p});

        const handle = try std.fs.openFileAbsolute(p, .{ .mode = .read_only });
        const size: usize = switch (builtin.os.tag) {
            .linux => (try handle.metadata()).inner.size(),
            else => @panic("OS not supported!"),
        };

        std.debug.print("{s} ({} bytes)\n", .{ p, size });

        std.debug.print("allocating args file...\n", .{});
        const file = try handle.readToEndAlloc(alloc.*, size);
        
        var argslist = std.ArrayList([:0]u8).init(alloc.*);

        std.debug.print("spliting args file...\n", .{});
        var args_iterator = std.mem.splitSequence(u8, file, " ");
        while (args_iterator.next()) |arg| try argslist.append(@constCast(@ptrCast(arg)));

        std.debug.print("replacing args...\n", .{});
        utils.args_handler.set_args(try argslist.toOwnedSlice());
    }
}

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L563
// part of this function is ignored due of too much effort for unecessary things :p
fn identify_version() void {}
