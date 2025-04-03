const root = @import("root");
const src = root.doom_src;

const i = src.i;

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/i_system.c#L107
pub fn init() void {
    i.sound.init_sound();
}
