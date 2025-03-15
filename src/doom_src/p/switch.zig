const src = @import("root").doom_src;

const p = @import("p.zig");
const r = src.r;
const gamestate = src.gamestate;

var switchlist: [p.spec.MAXSWITCHES * 2]i32 = undefined;
var numswitches: usize = undefined;

//
// CHANGE THE TEXTURE OF A WALL SWITCH TO ITS OPPOSITE
//
const alphSwitchList = [_]p.spec.SwitchList {
    .{ .name1 = "SW1BRCOM", .name2 = "SW2BRCOM", .episode = 1},
    .{ .name1 = "SW1BRN1",  .name2 = "SW2BRN1",  .episode = 1},
    .{ .name1 = "SW1BRN2",  .name2 = "SW2BRN2",  .episode = 1},
    .{ .name1 = "SW1BRNGN", .name2 = "SW2BRNGN", .episode = 1},
    .{ .name1 = "SW1BROWN", .name2 = "SW2BROWN", .episode = 1},
    .{ .name1 = "SW1COMM",  .name2 = "SW2COMM",  .episode = 1},
    .{ .name1 = "SW1COMP",  .name2 = "SW2COMP",  .episode = 1},
    .{ .name1 = "SW1DIRT",  .name2 = "SW2DIRT",  .episode = 1},
    .{ .name1 = "SW1EXIT",  .name2 = "SW2EXIT",  .episode = 1},
    .{ .name1 = "SW1GRAY",  .name2 = "SW2GRAY",  .episode = 1},
    .{ .name1 = "SW1GRAY1", .name2 = "SW2GRAY1", .episode = 1},
    .{ .name1 = "SW1METAL", .name2 = "SW2METAL", .episode = 1},
    .{ .name1 = "SW1PIPE",  .name2 = "SW2PIPE",  .episode = 1},
    .{ .name1 = "SW1SLAD",  .name2 = "SW2SLAD",  .episode = 1},
    .{ .name1 = "SW1STARG", .name2 = "SW2STARG", .episode = 1},
    .{ .name1 = "SW1STON1", .name2 = "SW2STON1", .episode = 1},
    .{ .name1 = "SW1STON2", .name2 = "SW2STON2", .episode = 1},
    .{ .name1 = "SW1STONE", .name2 = "SW2STONE", .episode = 1},
    .{ .name1 = "SW1STRTN", .name2 = "SW2STRTN", .episode = 1},
};

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/p_switch.c#L107
pub fn init_switch_list() void {
    var episode: usize = 1;

    if (gamestate.gamemode == .registered)
        episode = 2
    else if (gamestate.gamemode == .commecial)
        episode = 3;

    var index: usize = 0;
    var i: usize = 0;
    while (i < p.spec.MAXSWITCHES) : ({ index += 1; i += 1; }) {
        if (alphSwitchList[i].episode == 0) {
            numswitches = index / 2;
            switchlist[index] = -1;
            break;
        }

        if (alphSwitchList[i].episode <= episode)
        {
            switchlist[index] = r.data.texture_num_for_name(alphSwitchList[i].name1);
            switchlist[index + 1] = r.data.texture_num_for_name(alphSwitchList[i].name2);
            index += 2;
        }
    }
}
