const std = @import("std");
const root = @import("root");

const w = root.doom_src.w;

const print = std.debug.print;

// R_InitData:
//  Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
pub fn init_data() void {
    init_textures();
    print("InitTextures\n", .{});
    // R_InitFlats ();
    print("InitFlats\n", .{});
    // R_InitSpriteLumps ();
    print("InitSprites\n", .{});
    // R_InitColormaps ();
    print("InitColormaps\n", .{});
}

fn init_textures() void {
    // Load the patch names from pnames.lmp.
    var name: [9]u8 = undefined;
    name[8] = 0;

    _ = w.wad.cache_lump_name(@ptrCast(@alignCast(@constCast("PNAMES"))), .static);

}
