const std = @import("std");
const root = @import("root");

const w = root.doom_src.w;
const z = root.doom_src.z;

const print = std.debug.print;
const force_endianness = root.utils.force_endianness;

const MapPatch = extern struct {
    originx: i16,
    originy: i16,
    patch: i16,
    stepdir: i16,
    colormap: i16,
};
const MapTexture = extern struct {
    name: [8]i8,
    masked: bool,
    width: i16,
    height: i16,
    columndirectory: **anyopaque, // OBSOLETE
    patchcount: i16,
    patches: [1]MapPatch

};
const TexPath = struct {
    originx: i32,
    originy: i32,
    patch: i32
};
const Texture = struct {
    name: [8]i8,
    width: i16,
    height: i16,
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patchcount: i16,
    patches: [1]MapPatch
};

const FRACBITS = 16;

var textures: []*Texture = undefined;
var texturecolumnlump: [][]i16 = undefined;
var texturecolumnofs: [][]u16 = undefined;
var texturecomposite: []i32 = undefined;
var texturecompositesize: [][]u8 = undefined;
var texturewidthmask: []i32 = undefined;
var textureheight: []i32 = undefined;

var total_width: i32 = 0;

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

    for(0..num_map_patches) |i| {
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

    const num_textures1 = std.mem.readInt(u32, maptex1[0..4], .little);
    var num_textures2: u32 = undefined;

    var maxoff = w.wad.lump_length(w.wad.get_num_for_name("TEXTURE1"));
    var maxoff2: i32 = undefined;

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

    const _size_0 = num_textures * @sizeOf([]usize);
    textures = @as([*]*Texture, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    texturecolumnlump    = @as([*][]i16, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    texturecolumnofs     = @as([*][]u16, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    texturecomposite     = @as([*]i32, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    texturecompositesize = @as([*][]u8, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    texturewidthmask     = @as([*]i32, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];
    textureheight        = @as([*]i32, @ptrCast(@alignCast(z.zone.malloc(_size_0, .static, null))))[0..@intCast(num_textures * 4)];

    total_width = 0;

    //  Really complex printing shit...
    const temp_1 = w.wad.get_num_for_name("S_START"); // P_???????
    const temp_2 = w.wad.get_num_for_name("S_END") - 1;
    const temp_3: usize = @intCast(@divTrunc(temp_2 - temp_1 + 63, 64) + @divTrunc(num_textures + 63, 64));

    std.debug.print("[", .{});
    for (0..temp_3) |_|
        std.debug.print(" ", .{});
    std.debug.print("         ]", .{});

    for (0..temp_3) |_|
        std.debug.print("\x08", .{});
    std.debug.print("\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08", .{});	

    
}
