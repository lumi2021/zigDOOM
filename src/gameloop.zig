const std = @import("std");
const root = @import("root");
const system = root.system;
const game = root.game;
const gamestate = root.game_state;
const video = root.rendering.video;
const wad = root.resources.wad;

var singletics = true;
pub var running = true;
var advancedemo = false;

var demosequence: isize = 0;
var pagetic: usize = 0;
var pagename: []const u8 = undefined;


pub fn startTitle() void {
    demosequence = -1;
    advanceDemo();
}
pub fn advanceDemo() void {
    advancedemo = true;
}

pub fn gameloop() !noreturn {

    try system.init_graphics();

    while (running) {

        system.start_frame();


        if (singletics) {
            system.start_tic();
            system.process_events();
            // TODO G_BuildTiccmd
            doAdvanceDemo();
        } else {
           // doAdvanceDemo();
        }


        system.display();
    }

    std.process.exit(0);    
}

pub fn pageDrawer() void {
    video.draw_patch(0, 0, 0,
        @ptrCast(@alignCast(wad.cache_lump_name(pagename, .cache).ptr)));
}


fn doAdvanceDemo() void {

    game.players[0].playerState = .alive;
    advancedemo = false;
    game.usergame = false;
    game.paused = false;
    game.gameaction = .nothing;

    if (gamestate.gamemode == .retail)
        demosequence = @rem(demosequence+1, 7)
    else
        demosequence = @rem(demosequence+1, 6);
    
    switch (demosequence) {
        0 => {
            if (gamestate.gamemode == .commecial) pagetic = 35 * 11
            else pagetic = 170;
            game.gamestate = .demoscreen;
            pagename = "TITLEPIC";
        },
        else => {}
    }

}
