const std = @import("std");
const root = @import("root");

const w = root.doom_src.w;
const z = root.doom_src.z;

const print = std.debug.print;
const force_endianness = root.utils.force_endianness;

// R_InitData:
//  Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
pub fn init_data() !void {
    try init_textures();
    print("InitTextures\n", .{});
    // R_InitFlats ();
    print("InitFlats\n", .{});
    // R_InitSpriteLumps ();
    print("InitSprites\n", .{});
    // R_InitColormaps ();
    print("InitColormaps\n", .{});
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L411
fn init_textures() !void {
    // Load the patch names from pnames.lmp.
    const names = w.wad.cache_lump_name("PNAMES", .static);    
    const num_map_patches: u32 = std.mem.readInt(u32, names[0..4], .little);

    var names_p = names;
    names_p.ptr = @ptrFromInt(@intFromPtr(names.ptr) + 4);

    const patchlookup = try root.allocator.alloc(i32, num_map_patches);
    defer root.allocator.free(patchlookup);

    var name: [9]u8 = undefined;
    name[8] = 0;

    var i: usize = 0;
    while (i < num_map_patches) : (i += 1) {
        const start = i * 8;
        const end = (i+1) * 8;

        name[0..8].* = names_p[start..end][0..8].*;
        patchlookup[i] = w.wad.check_num_for_name(&name);
    }
    // bro this is unsafe as fuck lol
    z.zone.free(@ptrCast(names));

    // Load the map texture definitions from textures.lmp.
    // The data is contained in one or two lumps,
    //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.

    const maptex1 = w.wad.cache_lump_name("TEXTURE1", .static);
    var maptex2: ?[]u8 = undefined;
    const maptex = maptex1;

    const num_textures1 = std.mem.readInt(u32, maptex[0..4], .little);
    var num_textures2: u32 = undefined;

    const maxoff = w.wad.lump_length(w.wad.get_num_for_name("TEXTURE1"));
    var maxoff2: i32 = undefined;

    var directory = maptex;
    directory.ptr = @ptrFromInt(@intFromPtr(directory.ptr) + 4);

    if (w.wad.check_num_for_name("TEXTURE2") != -1) {
        maptex2 =  w.wad.cache_lump_name("TEXTURE2", .static);
        num_textures2 = std.mem.readInt(u32, maptex2.?[0..4], .little);
        maxoff2 = w.wad.lump_length(w.wad.get_num_for_name("TEXTURE2"));
    } else {
        maptex2 = null;
        num_textures2 = 0;
        maxoff2 = 0;
    }

    const num_textures: i32 = @intCast(num_textures1 + num_textures2);

    var textures: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var texturecolumnlump: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var texturecolumnofs: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var texturecomposite: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var texturecompositesize: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var texturewidthmask: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));
    var textureheight: *[]u8 = @ptrCast(@alignCast(z.zone.malloc(num_textures * 4, .static, null)));

    var total_width: i32 = 0;

    //	Really complex printing shit...
    const temp_1 = w.wad.get_num_for_name("S_START"); // P_???????

    _ = temp_1;
    _ = maxoff;

    total_width = undefined;
    textures = undefined;
    texturecolumnlump = undefined;
    texturecolumnofs = undefined;
    texturecomposite = undefined;
    texturecompositesize = undefined;
    texturewidthmask = undefined;
    textureheight = undefined;
}
