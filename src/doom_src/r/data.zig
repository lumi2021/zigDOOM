const std = @import("std");
const root = @import("root");

const w = root.doom_src.w;
const z = root.doom_src.z;
const r = root.doom_src.r;

const print = std.debug.print;
const fend = root.utils.force_endianness;

// Texture definition.
// Each texture is composed of one or more patches,
// with patches being lumps stored in the WAD.
// The lumps are referenced by number, and patched
// into the rectangular texture space using origin
// and possibly other attributes.
const MapPatch = extern struct {
    originx: i16,
    originy: i16,
    patch: i16,
    stepdir: i16,
    colormap: i16,
};

// Texture definition.
// A DOOM wall texture is a list of patches
// which are to be combined in a predefined order.
const MapTexture = extern struct {
    name: [8]u8,
    masked: u32, // yeah booleans for some reason are 32 bit in C
    width: i16,
    height: i16,
    columndirectory: u32, // OBSOLETE
    patchcount: i16,
    patches: MapPatch
};

// A single patch from a texture definition,
//  basically a rectangular area within
//  the texture rectangle.
const TexPatch = struct {
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    originx: i32,
    originy: i32,
    patch: i32
};

// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
const Texture = struct {
    name: []u8,
    width: i16,
    height: i16,
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patchcount: i16,
    patches: [*]TexPatch
};
const Patch = r.defs.Patch;

const FRACBITS = 16;

var num_textures: i32 = undefined;
var textures: [*]*Texture = undefined;
var texturecolumnlump: [*][*]i16 = undefined;
var texturecolumnofs: [*][*]u16 = undefined;
var texturecomposite: [*]i32 = undefined;
var texturecompositesize: [*]i32 = undefined;
var texturewidthmask: [*]i32 = undefined;
var textureheight: [*]i32 = undefined;

// for global animation
var flat_translation: [*]i32 = undefined;
var texture_translation: [*]i32 = undefined;

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

    // Load the patch names from pnames.lmp.
    var name : [9]u8 = undefined;
    name[8] = 0;

    const names = w.wad.cache_lump_name("PNAMES", .static);

    const nummappatches = std.mem.readInt(u32, names[0..4], .little);
    const patchlookup = root.allocator.alloc(i32, nummappatches) catch unreachable;
    defer root.allocator.free(patchlookup);

    for (0..@intCast(nummappatches)) |i| {
        @memcpy(name[0..8], names[(4 + i * 8).. (12 + i * 8)]);
        patchlookup[i] = w.wad.check_num_for_name(&name);
    }
    z.zone.free(names);

    // Load the map texture definitions from textures.lmp.
    // The data is contained in one or two lumps,
    //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    const maptex1: [*]u8 = w.wad.cache_lump_name("TEXTURE1", .static);
    const maxoff1 = w.wad.lump_length(w.wad.get_num_for_name("TEXTURE1"));
    const numtextures1: i32 = std.mem.readInt(i32, maptex1[0..4], .little);

    var maptex2: ?[*]u8 = undefined;
    var maxoff2: i32 = undefined;
    var numtextures2: i32 = undefined;

    if (w.wad.check_num_for_name("TEXTURE2") != -1) {
        maptex2 = w.wad.cache_lump_name("TEXTURE2", .static);
        maxoff2 = w.wad.lump_length(w.wad.get_num_for_name("TEXTURE1"));
        numtextures2 = std.mem.readInt(i32, maptex2.?[0..4], .little);
    } else {
        maptex2 = null;
        maxoff2 = 0;
        numtextures2 = 0;
    }
    num_textures = numtextures1 + numtextures2;

    textures = z.zone.malloc_buf(*Texture, num_textures, .static, null);
    texturecolumnlump = z.zone.malloc_buf([*]i16, num_textures, .static, null);
    texturecolumnofs = z.zone.malloc_buf([*]i16, num_textures, .static, null);
    texturecomposite = z.zone.malloc_buf(i32, num_textures, .static, null);
    texturecompositesize = z.zone.malloc_buf(i32, num_textures, .static, null);
    texturewidthmask = z.zone.malloc_buf(i32, num_textures, .static, null);
    textureheight = z.zone.malloc_buf(i32, num_textures, .static, null);

    total_width = 0;

    // Really complex printing shit...
    const temp1 = w.wad.get_num_for_name("S_START");
    const temp2 = w.wad.get_num_for_name("S_END") - 1;
    const temp3 = @divTrunc((temp2 - temp1 + 63), 64) + @divTrunc((num_textures + 63), 64);

    print("[", .{});
    for (0 .. @intCast(temp3)) |_| print(" ", .{});
    print("         ]", .{});

    for (0 .. @intCast(temp3)) |_| print("\x08", .{});
    print("\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08", .{});

    var maptex: [*]u8 = maptex1;
    var directory: [*]i32 = @ptrCast(@alignCast(maptex));
    directory = directory[1..];
    var maxoff = maxoff1;

    var i: usize = 0;
    while (i < num_textures) : ({ i += 1; directory = directory[1..]; }) {
        if ((i & 63) == 0) print(".", .{});

        if (i == numtextures1) {
            maptex = maptex2.?;
            maxoff = maxoff2;
            directory = @ptrCast(@alignCast(maptex));
            directory = directory[1..];
        }

        const offset: usize = @intCast(directory[0]);

        if (offset > maxoff) @panic("R_InitTextures: bad texture directory");

        const mtexture: *align(1) MapTexture = @ptrCast(&maptex[offset]);

        var texture: *Texture = z.zone.malloc_obj(Texture, .static, null);
        texture.patches = z.zone.malloc_buf(TexPatch, fend(mtexture.patchcount), .static, null);
        textures[i] = texture;

        texture.width = fend(mtexture.width);
        texture.height = fend(mtexture.height);
        texture.patchcount = fend(mtexture.patchcount);

        texture.name = std.mem.sliceTo(&mtexture.name, 0);

        var mpatch: [*]align(1) MapPatch = @ptrCast(&mtexture.patches);
        var patch: [*]align(1) TexPatch = texture.patches;

        var j: usize = 0;
        while (j < texture.patchcount) : ({ j += 1; mpatch = mpatch[1..]; patch = patch[1..]; }) {

            patch[0].originx = fend(mpatch[0].originx);
            patch[0].originy = fend(mpatch[0].originy);
            patch[0].patch = patchlookup[@intCast(fend(mpatch[0].patch))];

            if (patch[0].patch == -1) {
                std.debug.print("R_InitTextures: Missing patch in texture {s}", .{texture.name});
                @panic("R_InitTextures: Missing patch in texture");
            }
        }

        texturecolumnlump[i] = z.zone.malloc_buf(i16, texture.width, .static, null);
        texturecolumnofs[i] = z.zone.malloc_buf(u16, texture.width, .static, null);

        j = 1;
        while (j * 2 <= texture.width) j <<= 1;

        texturewidthmask[i] = @intCast(j-1);
        textureheight[i] = std.math.shl(i32, texture.height, FRACBITS);

        total_width += texture.width;
    }

    z.zone.free(maptex1);
    if (maptex2) |mt2| z.zone.free(mt2);

    // Precalculate whatever possible.
    for (0..@intCast(num_textures)) |j| generate_lookup(@intCast(j));

    // Create translation table for global animation.
    texture_translation = z.zone.malloc_buf(i32, num_textures + 1, .static, null);

    for (0..@intCast(num_textures)) |j| texture_translation[j] = @intCast(i);
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L581
fn init_flats() void {

    firstflat = w.wad.get_num_for_name("F_START") + 1;
    lastflat = w.wad.get_num_for_name("F_END") - 1;
    numflats = lastflat - firstflat + 1;

    // Create translation table for global animation.
    flat_translation = z.zone.malloc_buf(i32, numflats + 1, .static, null);

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

    spritewidth = z.zone.malloc_slice(i32, numspritelumps, .static, null);
    spriteoffset = z.zone.malloc_slice(i32, numspritelumps, .static, null);
    spritetopoffset = z.zone.malloc_slice(i32, numspritelumps, .static, null);

    for (0..@intCast(numspritelumps)) |i| {
        if ((i & @as(usize, 63)) == 0) print(".", .{});

        const patch: *Patch = @ptrCast(@alignCast(w.wad.cache_lump_num(firstspritelump + 1, .cache)));
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

    colormaps = z.zone.malloc_slice(u8, length, .static, null);
    colormaps.ptr = @ptrFromInt((@intFromPtr(colormaps.ptr) + 255) & ~@as(usize, 0xFF));
    w.wad.read_lump(lump, colormaps.ptr);
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

    for (0..@intCast(texture.patchcount)) |i| {
        const patch = texture.patches[i];

        const realpatch: *Patch = @ptrCast(@alignCast(w.wad.cache_lump_num(patch.patch, .cache)));
        
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
            collump[@intCast(x)] = @intCast(patch.patch);
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
        if (std.mem.eql(u8, std.mem.sliceTo(name, 0), textures[i].name)) return @intCast(i);
    }
    return -1;
}
