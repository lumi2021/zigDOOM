const std = @import("std");
const root = @import("root");

const w = root.doom_src.w;
const z = root.doom_src.z;
const r = root.doom_src.r;

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
    name: [8:0]u8,
    masked: u32, // yeah booleans for some reason are 32 bit in C
    width: i16,
    height: i16,
    columndirectory: u32, // OBSOLETE
    patchcount: i16,
    patches: MapPatch
};
const TexPath = struct {
    originx: i32,
    originy: i32,
    patch: i32
};
const Texture = extern struct {
    name: [8]u8,
    width: i16,
    height: i16,
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patchcount: i16,
    patches: MapPatch
};
const Patch = r.defs.Patch;

const FRACBITS = 16;

var num_textures: i32 = undefined;
var textures: []*Texture = undefined;
var texturecolumnlump: [][]i16 = undefined;
var texturecolumnofs: [][]u16 = undefined;
var texturecomposite: []i32 = undefined;
var texturecompositesize: []i32 = undefined;
var texturewidthmask: []i32 = undefined;
var textureheight: []i32 = undefined;

// for global animation
var flat_translation: []i32 = undefined;
var texture_translation: []i32 = undefined;

var total_width: i32 = 0;

// flats
var firstflat: i32 = undefined;
var lastflat: i32 = undefined;
var numflats: i32 = undefined;

// Sprites
var firstspritelump: i32 = undefined;
var lastspritelump: i32 = undefined;
var numspritelumps: i32 = undefined;

var spritewidth: []i32 = undefined;
var spriteoffset: []i32 = undefined;
var spritetopoffset: []i32 = undefined;

// colmaps
var colormaps: []u8 = undefined;

// R_InitData:
//  Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
pub fn init_data() void {
    init_textures();
    //print("\nInitTextures", .{});
    init_flats();
    //print("\nInitFlats", .{});
    init_sprite_lumps();
    //print("\nInitSprites", .{});
    init_colormaps();
    //print("\nInitColormaps", .{});
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L411
fn init_textures() void {



    @panic("Reached end");
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L581
fn init_flats() void {

    firstflat = w.wad.get_num_for_name("F_START") + 1;
    lastflat = w.wad.get_num_for_name("F_END") - 1;
    numflats = lastflat - firstflat + 1;

    // Create translation table for global animation.
    flat_translation = z.zone.malloc(i32, (numflats+1)*4, .static, null);

    for (0..@intCast(numflats)) |i| {
        flat_translation[i] = @intCast(i);
    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L603
fn init_sprite_lumps() void {

    firstspritelump = w.wad.get_num_for_name("S_START") + 1;
    lastspritelump = w.wad.get_num_for_name("S_END") - 1;
    numspritelumps = lastspritelump - firstspritelump + 1;

    spritewidth = z.zone.malloc(i32, numspritelumps * @sizeOf(i32), .static, null);
    spriteoffset = z.zone.malloc(i32, numspritelumps * @sizeOf(i32), .static, null);
    spritetopoffset = z.zone.malloc(i32, numspritelumps * @sizeOf(i32), .static, null);

    for (0..@intCast(numspritelumps)) |i| {
        if ((i & @as(usize, 63)) == 0) std.debug.print(".", .{});

        const patch: *Patch = @ptrCast(@alignCast(w.wad.cache_lump_num(firstspritelump + 1, .cache).ptr));
        spritewidth[i] = std.math.shlExact(i32, patch.width, FRACBITS) catch unreachable;
        spriteoffset[i] = std.math.shlExact(i32, patch.leftoffset, FRACBITS) catch unreachable;
        spritetopoffset[i] = std.math.shlExact(i32, patch.topoffset, FRACBITS) catch unreachable;

    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L633
fn init_colormaps() void {
    // Load in the light tables, 
    //  256 byte align tables.

    const lump = w.wad.get_num_for_name("COLORMAP");
    const length = w.wad.lump_length(lump) + 255;

    colormaps = z.zone.malloc(u8, length, .static, null);
    colormaps.ptr = @ptrFromInt((@intFromPtr(colormaps.ptr) + 255) & ~@as(usize, 0xFF));
    w.wad.read_lump(lump, colormaps);
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L296
fn generate_lookup(texnum: i32) void {
// FIXME this function is generating weird lines on the console,
// i belive this is not right

    var texture: *Texture = textures[@intCast(texnum)];

    // Composited texture not created yet.
    texturecomposite[@intCast(texnum)] = 0;

    texturecompositesize[@intCast(texnum)] = 0;
    const collump  = texturecolumnlump[@intCast(texnum)];
    const colofs = texturecolumnofs[@intCast(texnum)];

    // Now count the number of columns
    //  that are covered by more than one patch.
    // Fill in the lump / offset, so columns
    //  with only a single patch are all done.
    const patchcount = root.allocator.alloc(u8, @intCast(texture.width)) catch unreachable;
    defer root.allocator.free(patchcount);

    @memset(patchcount, 0);
    const patch_l: [*]MapPatch = @ptrCast(@alignCast(&texture.patches));

    for (0..@intCast(texture.patchcount)) |i| {
        const patch = patch_l[i];

        const patch_patch: i32 = @bitCast(@as(u32, @intCast(@as(u16, @bitCast(patch.patch)))));
        const realpatch: *Patch = @ptrCast(@alignCast(w.wad.cache_lump_num(patch_patch, .cache).ptr));
        
        const x1 = patch.originx;
        var x2 = x1 + realpatch.width;

        var x: i64 = undefined;
        if (x1 < 0) {
            x = 0;
        } else x = x1;

        if (x2 > texture.width)
            x2 = texture.width;
        

        while (x < x2) : (x += 1) {
            const realpatch_columnoffs = @as([*]u32, @ptrCast(&realpatch.columnoffs));

            patchcount[@intCast(x)] += 1;
            collump[@intCast(x)] = patch.patch;
            colofs[@intCast(x)] = @intCast(realpatch_columnoffs[@intCast(x-x1)] + 3);
        }

        while (x < texture.width) : (x += 1) {
            
            if (patchcount[@intCast(x)] == 0) {
                // doom uses printf here but i think it is better if the release
                // don't fuck with the little loading bar :3
                // root.print_log("R_GenerateLookup: column without a patch ({s})\n", .{texture.name});
                return;
            }

            if (patchcount[@intCast(x)] > 1) {
                // Use the cached block.
                collump[@intCast(x)] = -1;
                colofs[@intCast(x)] = @intCast(texturecompositesize[@intCast(texnum)]);

                if (texturecompositesize[@intCast(texnum)] > 0x100000 - @as(usize, @intCast(texture.height))) {
                    std.debug.print("R_GenerateLookup: texture {} is >64k", .{texnum});
                    @panic("R_GenerateLookup: texture is >64k");
                }

                texturecompositesize[@intCast(texnum)] += texture.height;
            }

        }
    }

    texture = undefined;
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L718
pub fn texture_num_for_name(name: [:0]const u8) i32 {
    const i = check_texture_num_for_name(name);
    if (i == -1) {
        std.debug.print("R_FlatNumForName: {s} not found\r\n", .{name});
        @panic("R_FlatNumForName: not found");
    }
    return i;
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L718
pub fn check_texture_num_for_name(name: [:0]const u8) i32 {
       // "NoTexture" marker.
    if (name[0] == '-') return 0;

    for (0 .. @intCast(num_textures)) |i| {
        if (std.mem.eql(u8, std.mem.sliceTo(name, 0), std.mem.sliceTo(&textures[i].name, 0))) return @intCast(i);
    }
    return -1;
}
