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
    name: [8]u8,
    masked: u32, // yeah booleans for some reason are 32 bit in C
    width: i16,
    height: i16,
    columndirectory: u32, // OBSOLETE
    patchcount: i16,
    patches: [1]MapPatch
};
const TexPath = struct {
    originx: i32,
    originy: i32,
    patch: i32
};
const Texture = struct {
    name: [8]u8,
    width: i16,
    height: i16,
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patchcount: i16,
    patches: [1]MapPatch
};
const Path = r.defs.Patch;

const FRACBITS = 16;

var textures: []*Texture = undefined;
var texturecolumnlump: [][]i16 = undefined;
var texturecolumnofs: [][]u16 = undefined;
var texturecomposite: []i32 = undefined;
var texturecompositesize: [][]u8 = undefined;
var texturewidthmask: []i32 = undefined;
var textureheight: []i32 = undefined;

// for global animation
var flat_translation: []i32 = undefined;
var texture_translation: []i32 = undefined;

var total_width: i32 = 0;

// R_InitData:
//  Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
pub fn init_data() !void {
    try init_textures();
    print("\nInitTextures", .{});
    // R_InitFlats ();
    print("\nInitFlats", .{});
    // R_InitSpriteLumps ();
    print("\nInitSprites", .{});
    // R_InitColormaps ();
    print("\nInitColormaps", .{});
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
    var maptex = @intFromPtr(maptex1.ptr);
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

    var directory_ptr = maptex + 4;
    for (0..@intCast(num_textures)) |i| {
        
        if ((i & 63) == 0) std.debug.print(".", .{});

        if (i == num_textures1) {
            // Start looking in second texture file.
            maptex = @intFromPtr(maptex2.?.ptr);
            maxoff = maxoff2;
            directory_ptr = maptex + @sizeOf(usize);
        }

        const offset: usize = @intCast(@as(*i32, @ptrFromInt(directory_ptr)).*);

        if (offset > maxoff)
            @panic("R_InitTextures: bad texture directory");
        
        const mtexture: *align(1) MapTexture = @ptrFromInt(maptex + offset);

        var texture: *Texture = @ptrCast(@alignCast(z.zone.malloc(
            @sizeOf(Texture) + @sizeOf(TexPath) * (mtexture.patchcount),
            // do `mtexture.patchcount - 1` will open it for a possible buffer
            // overflow. i think it's zig fault :p
            .static, null)));
        textures[i] = texture;

        texture.width = mtexture.width;
        texture.height = mtexture.height;
        texture.patchcount = mtexture.patchcount;
        
        texture.name = mtexture.name;

        if (texture.patchcount > 0) {
            const mpatch_arr: [*]volatile MapPatch = @ptrCast(@alignCast(&mtexture.patches));
            const patch_arr: [*]volatile MapPatch = @ptrCast(@alignCast(&texture.patches));

            for (0..@intCast(texture.patchcount)) |j| {
                const mpatch = mpatch_arr[j];
                var patch = patch_arr[j];


                patch.originx = mpatch.originx;
                patch.originy = mpatch.originy;
                patch.patch = @intCast(patchlookup[@intCast(mpatch.patch)]);

                if (patch.patch == -1) {
                    std.debug.print("R_InitTextures: Missing patch in texture {s}", .{texture.name});
                    @panic("R_InitTextures: Missing patch in texture");
                }

            }
        }

        texturecolumnlump[i] = @as([*]i16, @ptrCast(@alignCast(z.zone.malloc(texture.width*2, .static, null))))[0..@intCast(texture.width*2)];
        texturecolumnofs[i] = @as([*]u16, @ptrCast(@alignCast(z.zone.malloc(texture.width*2, .static, null))))[0..@intCast(texture.width*2)];

        var j: usize = 1;
        while (j * 2 <= texture.width) j <<= 1;

        texturewidthmask[i] = @intCast(j - 1);
        textureheight[i] = std.math.shlExact(i32, texture.height, FRACBITS) catch unreachable;

        total_width += texture.width;
        directory_ptr += 4;
    }

    z.zone.free(@ptrCast(maptex1.ptr));
    if (maptex2 != null) z.zone.free(@ptrCast(maptex2.?.ptr));

    // Precalculate whatever possible.
    for (0..@intCast(num_textures)) |i| {
        generate_lookup(@intCast(i));
    }

    // Create translation table for global animation.
    texture_translation = @as([*]i32, @ptrCast(@alignCast(z.zone.malloc((num_textures+1)*4, .static, null))))[0..@intCast((num_textures+1)*4)];

    for (0..@intCast(num_textures)) |i| {
        texture_translation[i] = @intCast(i);
    }

    maxoff = undefined;
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_data.c#L296
fn generate_lookup(texnum: i32) void {

    var texture: *Texture = textures[@intCast(texnum)];

    // Composited texture not created yet.
    texturecomposite[@intCast(texnum)] = 0;

    //texturecompositesize[@intCast(texnum)] = 0;
    const collump  = texturecolumnlump[@intCast(texnum)];
    const colofs = texturecolumnofs[@intCast(texnum)];

    // Now count the number of columns
    //  that are covered by more than one patch.
    // Fill in the lump / offset, so columns
    //  with only a single patch are all done.
    const patchcount = root.allocator.alloc(u8, @intCast(texture.width)) catch unreachable;
    defer root.allocator.free(patchcount);

    @memset(patchcount, 0);
    const patch: [*]MapPatch = @ptrCast(&texture.patches);

    for (0..@intCast(texture.patchcount)) |i| {

        std.debug.print(
                \\
                \\ p:  {0} {0X:0>8}
                \\ ox: {1} {1X:0>8}
                \\ oy: {2} {2X:0>8}
                \\ cm: {3} {3X:0>8}
                \\ sd: {4} {4X:0>8}
                \\
                ,.{
                    @as(u16, @bitCast(patch[i].patch)),
                    @as(u16, @bitCast(patch[i].originx)),
                    @as(u16, @bitCast(patch[i].originy)),
                    @as(u16, @bitCast(patch[i].colormap)),
                    @as(u16, @bitCast(patch[i].stepdir))
                });

        const patch_patch: i32 = @bitCast(@as(u32, @intCast(@as(u16, @bitCast(patch[i].patch)))));
        const realpatch: *Path = @ptrCast(@alignCast(w.wad.cache_lump_num(patch_patch, .cache).ptr));
        
        const x1 = patch[i].originx;
        var x2 = x1 + realpatch.width;

        var x: i64 = undefined;
        if (x1 < 0) {
            x = 0;
        } else x = x1;

        if (x2 > texture.width)
            x2 = texture.width;
        
        while (x < x2) : (x += 1) {
            std.debug.print("help", .{});

            patchcount[@intCast(x)] += 1;
            collump[@intCast(x)] = patch[i].patch;
            colofs[@intCast(x)] = @intCast(realpatch.columnoffs[@intCast(x-x1)] + 3);
        }

        while (x < texture.width) : (x += 1) {
            
            if (patchcount[0] == 0)
            {
                std.debug.print("R_GenerateLookup: column without a patch ({s})\n", .{texture.name});
                return;
            }

        }
    }
}
