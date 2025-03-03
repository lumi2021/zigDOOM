const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");

const dsrc = root.doom_src;
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
    root.print_log("V_Init: allocate screens.\n", .{});
    try dsrc.v.video.video_init();

    root.print_log("M_LoadDefaults: Load system defaults.\n", .{});
    try dsrc.m.misc.load_defaults();

    root.print_log("Z_Init: Init zone memory allocation daemon. \n", .{});
    try dsrc.z.zone.init();

    root.print_log("W_Init: Init WADfiles.\n", .{});
    try dsrc.w.wad.init_wads();

    // check for -file in shareware
    // TODO https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L1025-L1047

    if (dsrc.gamestate.modified_game) {
        std.debug.print(
        \\===========================================================================
	    \\ ATTENTION:  This version of DOOM has been modified.  If you would like to
	    \\get a copy of the original game, call 1-800-IDGAMES or see the readme file.
	    \\        You will not receive technical support for modified games.
	    \\                       press enter to continue
	    \\===========================================================================
        \\
        , .{});
        _ = try std.io.getStdIn().reader().readByte();
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
    root.print_log("M_Init: Init miscellaneous info.\n", .{});
    dsrc.m.menu.init();

    root.print_log("R_Init: Init DOOM refresh daemon - ", .{});
    dsrc.r.main.init();

    root.print_log("\nP_Init: Init Playloop state.\n", .{});
    dsrc.p.setup.init();

    root.print_log("I_Init: Setting up machine state.\n", .{});
    //I_Init ();

    root.print_log("D_CheckNetGame: Checking network game status.\n", .{});
    //D_CheckNetGame ();

    root.print_log("S_Init: Setting up sound.\n", .{});
    //S_Init (snd_SfxVolume /* *8 */, snd_MusicVolume /* *8*/ );

    root.print_log("HU_Init: Setting up heads up display.\n", .{});
    //HU_Init ();

    root.print_log("ST_Init: Init status bar.\n", .{});
    //ST_Init ();

    // to make sure nothing goes wrong
    root.print_dbg("dmain.zig ends here!\n", .{});
}

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L722
fn find_response_fine() !void {

    const found_path = utils.args_handler.garg_starthwith('@') catch null;

    if (found_path) |path| {
        const p = try std.fs.realpathAlloc(alloc.*, path);
        root.print_dbg("path found: {s}\n", .{p});

        const handle = try std.fs.openFileAbsolute(p, .{ .mode = .read_only });
        const size: usize = switch (builtin.os.tag) {
            .linux => (try handle.metadata()).inner.size(),
            else => @panic("OS not supported!"),
        };

        root.print_dbg("{s} ({} bytes)\n", .{ p, size });

        root.print_dbg("allocating args file...\n", .{});
        const file = try handle.readToEndAlloc(alloc.*, size);
        
        var argslist = std.ArrayList([:0]u8).init(alloc.*);

        root.print_dbg("spliting args file...\n", .{});
        var args_iterator = std.mem.splitSequence(u8, file, " ");
        while (args_iterator.next()) |arg| try argslist.append(@constCast(@ptrCast(arg)));

        root.print_dbg("replacing args...\n", .{});
        utils.args_handler.set_args(try argslist.toOwnedSlice());
    }
}

// https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/d_main.c#L563
// part of this function is ignored due of too much effort for unecessary things :p
fn identify_version() void {}
