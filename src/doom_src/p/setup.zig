const std = @import("std");
const doomsrc = @import("root").doom_src;

const p = doomsrc.p;
const r = doomsrc.r;

const sprnames = doomsrc.info.sprnames;

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/p_setup.c#L700
pub fn init() void {
    p.@"switch".init_switch_list();
    p.spec.init_pic_anims();
    r.things.init_sprites(@constCast(&sprnames));
}

