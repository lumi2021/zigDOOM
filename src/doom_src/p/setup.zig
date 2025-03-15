const p = @import("p.zig");

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/p_setup.c#L700
pub fn init() void {
    p.@"switch".init_switch_list();
    //P_InitPicAnims ();
    //R_InitSprites (sprnames);

}
