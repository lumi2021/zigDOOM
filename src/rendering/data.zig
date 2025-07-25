const std = @import("std");
const root = @import("root");
const wad = @import("../resources/wad.zig");
const zone = root.zone;


const FRACBITS = 16;

pub var textures: []*Texture = undefined;
var texturecolumnlump: [][]usize = undefined;
var texturecolumnofs: [][]usize = undefined;
var texturecomposite: []usize = undefined;
var texturecompositesize: []usize = undefined;
var texturewidthmask: []usize = undefined;
var textureheight: []usize = undefined;

// for global animation
var flat_translation: []usize = undefined;
var texture_translation: []usize = undefined;

var total_width: usize = 0;

// flats
pub var firstflat: usize = undefined;
pub var lastflat: usize = undefined;
pub var numflats: usize = undefined;

// Sprites
pub var firstspritelump: usize = undefined;
pub var lastspritelump: usize = undefined;
pub var numspritelumps: usize = undefined;

var spritewidth: []usize = undefined;
var spriteoffset: []isize = undefined;
var spritetopoffset: []isize = undefined;

// colmaps
var colormaps: []u8 = undefined;


/// Texture definition. \
/// Each texture is composed of one or more patches,
/// with patches being lumps stored in the WAD.
/// The lumps are referenced by number, and patched
/// into the rectangular texture space using origin
/// and possibly other attributes.
const MapPatch = extern struct {
    originx: i16,
    originy: i16,
    patch: i16,
    stepdir: i16,
    colormap: i16,
};

/// Texture definition.\
/// A DOOM wall texture is a list of patches
/// which are to be combined in a predefined order.
const MapTexture = extern struct {
    name: [8]u8,
    masked: u32, // yeah booleans for some reason are 32 bit in C
    width: i16,
    height: i16,
    columndirectory: u32, // OBSOLETE
    patchcount: i16,
    patches: MapPatch
};

/// A single patch from a texture definition, \
/// basically a rectangular area within
/// the texture rectangle.
const TexPatch = struct {
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    originx: isize,
    originy: isize,
    patch: usize
};

/// A maptexturedef_t describes a rectangular texture,
/// which is composed of one or more mappatch_t structures
/// that arrange graphic patches.
const Texture = struct {
    name: extern union {
        str: [8:0]u8,
        int: u64,
    },
    width: usize,
    height: usize,
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patches: []TexPatch
};
pub const Patch = extern struct {
    width: i16,             // bounding box size 
    height: i16,
    leftoffset: i16,        // pixels to the left of origin
    topoffset: i16,         // pixels below the origin 
    columnoffs: [8]i32      // only [width] used
};

/// Sprites are patches with a special naming convention
///  so they can be recognized by R_InitSprites. \
/// The base name is NNNNFx or NNNNFxFx, with
///  x indicating the rotation, x = 0, 1-7. z
/// The sprite and frame specified by a thing_t
///  is range checked at run time. \
/// A sprite is a patch_t that is assumed to represent
///  a three dimensional object and may have multiple
///  rotations pre drawn. \
/// Horizontal flipping is used to save space,
///  thus NNNNF2F5 defines a mirrored patch. \
/// Some sprites will only have one picture used
/// for all views: NNNNF0
pub const SpriteFrame = struct {
    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.
    rotate: i32,

    // Lump to use for view angles 0-7.
    lump: [8]i16,

    // Flip bit (1 = flip) to use for view angles 0-7.
    flip: [8]u8
};

/// A sprite definition:
///  a number of animation frames.
pub const SpriteDef = struct {
    numframes: i32,
    spriteframes: []SpriteFrame
};

pub fn init_data() !void {
    try init_textures();
    std.log.debug("\nInitTextures", .{});
    try init_flats();
    std.log.debug("\nInitFlats", .{});
    try init_sprite_lumps();
    std.log.debug("\nInitSprites", .{});
    try init_colormaps();
    std.log.debug("\nInitColormaps", .{});
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L411
fn init_textures() !void {

    // Load the patch names from pnames.lmp.
    var name : [9]u8 = undefined;
    name[8] = 0;

    const names = wad.cache_lump_name("PNAMES", .static);

    const nummappatches = std.mem.readInt(u32, names[0..4], .little);
    const patchlookup = zone.gpa.alloc(?usize, nummappatches) catch unreachable;
    defer zone.gpa.free(patchlookup);

    for (0..@intCast(nummappatches)) |i| {
        @memcpy(name[0..8], names[(4 + i * 8).. (12 + i * 8)]);
        patchlookup[i] = wad.check_num_for_name(&name);
    }
    zone.get(.static).free(names);

    // Load the map texture definitions from textures.lmp.
    // The data is contained in one or two lumps,
    //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    const maptex1: []u8 = wad.cache_lump_name("TEXTURE1", .static);
    const maxoff1 = wad.lump_length(wad.get_num_for_name("TEXTURE1"));
    const numtextures1: usize = @intCast(std.mem.readInt(i32, maptex1[0..4], .little));

    var maptex2: ?[]u8 = undefined;
    var maxoff2: usize = undefined;
    var numtextures2: usize = undefined;

    if (wad.check_num_for_name("TEXTURE2") != null) {
        maptex2 = wad.cache_lump_name("TEXTURE2", .static);
        maxoff2 = wad.lump_length(wad.get_num_for_name("TEXTURE1"));
        numtextures2 = @intCast(std.mem.readInt(i32, maptex2.?[0..4], .little));
    } else {
        maptex2 = null;
        maxoff2 = 0;
        numtextures2 = 0;
    }
    const num_textures: usize = @intCast(numtextures1 + numtextures2);

    textures = try zone.get(.static).alloc(*Texture, num_textures);
    texturecolumnlump = try zone.get(.static).alloc([]usize, num_textures);
    texturecolumnofs = try zone.get(.static).alloc([]usize, num_textures);
    texturecomposite = try zone.get(.static).alloc(usize, num_textures);
    texturecompositesize = try zone.get(.static).alloc(usize, num_textures);
    texturewidthmask = try zone.get(.static).alloc(usize, num_textures);
    textureheight = try zone.get(.static).alloc(usize, num_textures);

    total_width = 0;

    // Really complex printing shit...
    const temp1 = wad.get_num_for_name("S_START");
    const temp2 = wad.get_num_for_name("S_END") - 1;
    const temp3 = try std.math.divCeil(usize, temp2 - temp1, 64)
                + try std.math.divCeil(usize, num_textures, 64);

    std.log.info("[", .{});
    for (0 .. @intCast(temp3)) |_| std.log.info(" ", .{});
    std.log.info("         ]", .{});

    for (0 .. @intCast(temp3)) |_| std.log.info("\x08", .{});
    std.log.info("\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08", .{});

    var maptex: []u8 = maptex1;
    var directory: [*]i32 = @ptrCast(@alignCast(maptex));
    directory = directory[1..];
    var maxoff = maxoff1;

    var i: usize = 0;
    while (i < num_textures) : ({ i += 1; directory = directory[1..]; }) {
        if ((i & 63) == 0) std.log.info(".", .{});

        if (i == numtextures1) {
            maptex = maptex2.?;
            maxoff = maxoff2;
            directory = @ptrCast(@alignCast(maptex));
            directory = directory[1..];
        }

        const offset: usize = @intCast(directory[0]);

        if (offset > maxoff) @panic("R_InitTextures: bad texture directory");

        const mtexture: *align(1) MapTexture = @ptrCast(&maptex[offset]);

        var texture: *Texture = try zone.get(.static).create(Texture,);
        texture.patches = try zone.get(.static).alloc(TexPatch, @intCast(mtexture.patchcount));
        textures[i] = texture;

        texture.width = @intCast(mtexture.width);
        texture.height = @intCast(mtexture.height);

        @memcpy(&texture.name.str, &mtexture.name);

        var mpatch: [*]align(1) MapPatch = @ptrCast(&mtexture.patches);
        var patch: []TexPatch = texture.patches;

        var j: usize = 0;
        while (j < texture.patches.len) : ({ j += 1; mpatch = mpatch[1..]; patch = patch[1..]; }) {

            patch[0].originx = @intCast(mpatch[0].originx);
            patch[0].originy = @intCast(mpatch[0].originy);
            patch[0].patch = patchlookup[@intCast(mpatch[0].patch)].?;

            if (patch[0].patch == -1) {
                std.debug.print("R_InitTextures: Missing patch in texture {s}", .{texture.name});
                @panic("R_InitTextures: Missing patch in texture");
            }
        }

        texturecolumnlump[i] = try zone.get(.static).alloc(usize, @intCast(texture.width));
        texturecolumnofs[i] = try zone.get(.static).alloc(usize, @intCast(texture.width));

        j = 1;
        while (j * 2 <= texture.width) j <<= 1;

        texturewidthmask[i] = @intCast(j-1);
        textureheight[i] = std.math.shl(usize, texture.height, FRACBITS);

        total_width += texture.width;
    }

    zone.get(.static).free(maptex1);
    if (maptex2) |mt2| zone.get(.static).free(mt2);

    // Precalculate whatever possible.
    for (0..@intCast(num_textures)) |j| generate_lookup(@intCast(j));

    // Create translation table for global animation.
    texture_translation = try zone.get(.static).alloc(usize, num_textures + 1);

    for (0..@intCast(num_textures)) |j| texture_translation[j] = @intCast(i);
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L581
fn init_flats() !void {
    firstflat = wad.get_num_for_name("F_START") + 1;
    lastflat = wad.get_num_for_name("F_END") - 1;
    numflats = lastflat - firstflat + 1;

    // Create translation table for global animation.
    flat_translation = try zone.get(.static).alloc(usize, numflats + 1);

    for (0..@intCast(numflats)) |i| {
        flat_translation[i] = @intCast(i);
    }
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L603
fn init_sprite_lumps() !void {

    firstspritelump = wad.get_num_for_name("S_START") + 1;
    lastspritelump = wad.get_num_for_name("S_END") - 1;
    numspritelumps = lastspritelump - firstspritelump + 1;

    spritewidth = try zone.get(.static).alloc(usize, numspritelumps);
    spriteoffset = try zone.get(.static).alloc(isize, numspritelumps);
    spritetopoffset = try zone.get(.static).alloc(isize, numspritelumps);

    for (0..@intCast(numspritelumps)) |i| {
        if ((i & @as(usize, 63)) == 0) std.log.info(".", .{});

        const patch: *Patch = @ptrCast(@alignCast(wad.cache_lump_num(firstspritelump + 1, .cache)));
        spritewidth[i] = @intCast(std.math.shlExact(i32, patch.width, FRACBITS) catch unreachable);
        spriteoffset[i] = @intCast(std.math.shlExact(i32, patch.leftoffset, FRACBITS) catch unreachable);
        spritetopoffset[i] = @intCast(std.math.shlExact(i32, patch.topoffset, FRACBITS) catch unreachable);

    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L633
fn init_colormaps() !void {
    // Load in the light tables, 
    //  256 byte align tables.

    const lump = wad.get_num_for_name("COLORMAP");
    const length = wad.lump_length(lump) + 255;

    colormaps = try zone.get(.static).alloc(u8, length);
    colormaps.ptr = @ptrFromInt((@intFromPtr(colormaps.ptr) + 255) & ~@as(usize, 0xFF));
    wad.read_lump(lump, colormaps);
}


// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L296
fn generate_lookup(texnum: i32) void {

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
    const patchcount = zone.gpa.alloc(u8, @intCast(texture.width)) catch @panic("OOM");
    defer zone.gpa.free(patchcount);

    @memset(patchcount, 0);

    for (0..@intCast(texture.patches.len)) |i| {
        const patch = texture.patches[i];

        const realpatch: *Patch = @ptrCast(@alignCast(wad.cache_lump_num(patch.patch, .cache)));
        
        const x1 = patch.originx;
        var x2 = x1 + @as(isize, @intCast(realpatch.width));

        var x: isize = undefined;
        if (x1 < 0) {
            x = 0;
        } else x = x1;

        if (x2 > texture.width)
            x2 = @intCast(texture.width);
        

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
                collump[@intCast(x)] = @bitCast(@as(isize, -1));
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