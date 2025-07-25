const std = @import("std");
const root = @import("root");
const data = @import("data.zig");

const gamestate = root.game_state;
const zone = root.zone;
const wad = root.resources.wad;

var negonearray: [gamestate.SCREEN_WIDTH]i16 = undefined;
var screenheightarray: [gamestate.SCREEN_HEIGHT]i16 = undefined;

var sprites: []SpriteDef = undefined;
var numsprites: usize = undefined;

var sprtemp: [29]SpriteFrame = undefined;
var spritename: []const u8 = undefined;

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
///  x indicating the rotation, x = 0, 1-7. \
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
    rotate: isize,

    // Lump to use for view angles 0-7.
    lump: [8]i16,

    // Flip bit (1 = flip) to use for view angles 0-7.
    flip: [8]u8
};

/// A sprite definition:
///  a number of animation frames.
pub const SpriteDef = struct {
    numframes: usize,
    spriteframes: []SpriteFrame
};


/// Implementation of:
///     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L299
pub fn init_sprites(namelist: [][:0]const u8) !void {
    for (0 .. gamestate.SCREEN_WIDTH) |i| negonearray[i] = -1;
    try init_spritedefs(namelist);
}

/// Implementation of:
///     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L177 \
/// Pass list of sprite names (4 chars exactly) to be used. \
/// Builds the sprite rotation matrixes to account
///  for horizontally flipped sprites. \
/// Will report an error if the lumps are inconsistant. \
/// Only called at startup.
///
/// Sprite lump names are 4 characters for the actor,
///  a letter for the frame, and a number for the rotation. \
/// A sprite that is flippable will have an additional
///  letter/number appended. \
/// The rotation character can be 0 to signify no rotations.
fn init_spritedefs(namelist: [][:0]const u8) !void {

    // count the number of sprite names
    if (namelist.len == 0) return;
    sprites = try zone.get(.static).alloc(SpriteDef, namelist.len);

    const start = data.firstspritelump - 1;
    const end = data.lastspritelump + 1;

    // scan all the lump names for each of the names,
    //  noting the highest frame letter.
    // Just compare 4 characters as ints
    for (0..sprites.len) |i| {
        spritename = namelist[i];
        const sprtemp_asbyte: []i8 = @as([*]i8, @ptrCast(@alignCast(&sprtemp)))[0.. (29 * @sizeOf(SpriteFrame))];
        @memset(sprtemp_asbyte, -1);

        const intname = std.mem.readInt(u32, namelist[i][0 .. 4], .big);
        var maxframe: isize = -1;

        // scan the lumps,
	    //  filling in the frames for whatever is found
        for (@intCast(start+1) .. @intCast(end)) |l| {
            if (wad.lumpinfo[l].name.int & 0xFFFF == intname) {
                var frame = wad.lumpinfo[l].name.str[4] - 'A';
                const rotation = wad.lumpinfo[l].name.str[5] - '0';

                var patched: usize = undefined;
                if (gamestate.modified_game) patched = wad.get_num_for_name(&wad.lumpinfo[i].name.str)
                else patched = l;

                maxframe = install_sprite_lump(patched, frame, rotation, true);

                if (wad.lumpinfo[l].name.str[6] != 0) {
                    frame = wad.lumpinfo[l].name.str[7] - '0';
                    maxframe = install_sprite_lump(@intCast(l), frame, rotation, true);
                }
            }
        }

        // check the frames that were found for completeness
        if (maxframe == -1) {
            sprites[i].numframes = 0;
            continue;
        }

        maxframe += 1;

        for (0 .. @intCast(maxframe)) |frame| {
            switch (sprtemp[frame].rotate) {
                -1 => {
                    // no rotations were found for that frame at all
                    std.debug.panic("R_InitSprites: No patches found for {s} frame {c}\n", .{namelist[i], 'A' + @as(u8, @intCast(frame))});
                },
                
                0 => {
                    // only the first rotation is needed
                },

                1 => {
                    // must have all 8 frames
                    for (0 .. 8) |rotation| {
                        if (sprtemp[frame].lump[rotation] == -1) {
                            std.debug.panic("R_InitSprites: Sprite {s} frame {c} is missing rotations", .{namelist[i], 'A' + @as(u8, @intCast(frame))});
                        }
                    }
                },

                else => @panic("bruh zig is anoying af")
            }
        }

        // allocate space for the frames present and copy sprtemp to it
        sprites[i].numframes = @intCast(maxframe);
        sprites[i].spriteframes = try zone.get(.static).alloc(SpriteFrame, @intCast(maxframe));
        @memcpy(sprites[i].spriteframes, &sprtemp);
    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L106
fn install_sprite_lump(lump: usize, frame: usize, _rotation: usize, flipped: bool) isize {
    var rotation: usize = _rotation;

    if (frame >= 29 and rotation > 8) {
        std.debug.panic("Bad frame characters in lump {}", .{lump});
    }

    const maxframe: isize = if (frame > -1) @bitCast(frame) else -1;

    if (rotation == 0) {
        // the lump should be used for all rotations
        if (sprtemp[frame].rotate == 0) {
            std.debug.panic("R_InitSprites: Sprite {s} frame {c} has multip rot=0 lump\n", .{spritename, 'A' + @as(u8, @intCast(frame))});
        }

        if (sprtemp[frame].rotate == 1) {
            std.debug.panic("R_InitSprites: Sprite {s} frame {c} has rotations and a rot=0 lump\n", .{spritename, 'A' + @as(u8, @intCast(frame))});
        }

        sprtemp[frame].rotate = 0;
        for (0 .. 8) |rot| {
            sprtemp[frame].lump[rot] = @intCast(lump - data.firstspritelump);
            sprtemp[frame].flip[rot] = @intFromBool(flipped);
        }

        return 0;
    }

    // the lump is only used for one rotation
    if (sprtemp[frame].rotate == 0) {
        std.debug.print("R_InitSprites: Sprite {s} frame {c} has rotations and a rot=0 lump\n", .{spritename, 'A' + @as(u8, @intCast(frame))});
        @panic("R_InitSprites: Sprite frame has rotations and a rot=0 lump");
    }

    sprtemp[frame].rotate = 1;

    // make 0 based
    rotation -= 1;
    if (sprtemp[frame].lump[rotation] != -1) {
        std.debug.print("R_InitSprites: Sprite {s} : {c} : {c} has two lumps mapped to it\n", .{spritename, 'A' + @as(u8, @intCast(frame)), '1' + @as(u8, @intCast(rotation))});
        @panic("R_InitSprites: Sprite has two lumps mapped to it");
    }

    sprtemp[frame].lump[rotation] = @intCast(lump - data.firstspritelump);
    sprtemp[frame].flip[rotation] = @intFromBool(flipped);

    return maxframe;
}
