const std = @import("std");
const doomsrc = @import("root").doom_src;
const gamestate = doomsrc.gamestate;

const r = doomsrc.r;
const z = doomsrc.z;
const w = doomsrc.w;

var negonearray: [gamestate.SCREEN_WIDTH]i16 = undefined;
var screenheightarray: [gamestate.SCREEN_HEIGHT]i16 = undefined;

var sprites: [*]r.defs.SpriteDef = undefined;
var numsprites: usize = undefined;

var sprtemp: [29]r.defs.SpriteFrame = undefined;
var maxframe: i32 = undefined;
var spritename: []const u8 = undefined;

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L299
// R_InitSprites
// Called at program start.
pub fn init_sprites(namelist: [][:0]const u8) void {
    for (0 .. gamestate.SCREEN_WIDTH) |i| negonearray[i] = -1;
    init_spritedefs(namelist);
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L177
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant. 
// Only called at startup.
//
// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
fn init_spritedefs(namelist: [][:0]const u8) void {

    // count the number of sprite names
    numsprites = namelist.len;
    
    if (numsprites == 0) return;

    sprites = z.zone.malloc_buf(r.defs.SpriteDef, numsprites, .static, null);

    const start = r.data.firstspritelump - 1;
    const end = r.data.lastspritelump + 1;

    // scan all the lump names for each of the names,
    //  noting the highest frame letter.
    // Just compare 4 characters as ints
    for (0..numsprites) |i| {
        spritename = namelist[i];
        const sprtemp_asbyte: []i8 = @as([*]i8, @ptrCast(@alignCast(&sprtemp)))[0.. (29 * @sizeOf(r.defs.SpriteFrame))];
        @memset(sprtemp_asbyte, -1);

        maxframe = -1;
        const intname = std.mem.readInt(u32, namelist[i][0 .. 4], .big);

        // scan the lumps,
	    //  filling in the frames for whatever is found
        for (@intCast(start+1) .. @intCast(end)) |l| {
            if (w.wad.lumpinfo[l].name32[0] == intname) {
                var frame = w.wad.lumpinfo[l].name[4] - 'A';
                const rotation = w.wad.lumpinfo[l].name[5] - '0';

                var patched: i32 = undefined;
                if (doomsrc.gamestate.modified_game) patched = w.wad.get_num_for_name(&w.wad.lumpinfo[i].name)
                else patched = @intCast(l);

                install_sprite_lump(patched, frame, rotation, true);

                if (w.wad.lumpinfo[l].name[6] != 0) {
                    frame = w.wad.lumpinfo[l].name[7] - '0';
                    install_sprite_lump(@intCast(l), frame, rotation, true);
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
                    std.debug.print("R_InitSprites: No patches found for {s} frame {c}\n", .{namelist[i], 'A' + @as(u8, @intCast(frame))});
                    @panic("R_InitSprites: No patches found for frame");
                },
                
                0 => {
                    // only the first rotation is needed
                },

                1 => {
                    // must have all 8 frames
                    for (0 .. 8) |rotation| {
                        if (sprtemp[frame].lump[rotation] == -1) {
                            std.debug.print("R_InitSprites: Sprite {s} frame {c} is missing rotations", .{namelist[i], 'A' + @as(u8, @intCast(frame))});
                        }
                    }
                },

                else => @panic("bruh zig is anoying sometimes")
            }
        }

        // allocate space for the frames present and copy sprtemp to it
        sprites[i].numframes = maxframe;
        sprites[i].spriteframes = z.zone.malloc_slice(r.defs.SpriteFrame, maxframe, .static, null);
        @memcpy(sprites[i].spriteframes, &sprtemp);
    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L106
fn install_sprite_lump(lump: i32, frame: u32, _rotation: u32, flipped: bool) void {
    var rotation: u32 = _rotation;

    if (frame >= 29 and rotation > 8) {
        std.debug.print("Bad frame characters in lump {}", .{lump});
        @panic("Bad frame characters in lump");
    }

    if (@as(i32, @bitCast(frame)) > maxframe) maxframe = @bitCast(frame);

    if (rotation == 0) {
        // the lump should be used for all rotations
        if (sprtemp[frame].rotate == 0) {
            std.debug.print("R_InitSprites: Sprite {s} frame {c} has multip rot=0 lump\n", .{spritename, 'A' + @as(u8, @intCast(frame))});
            @panic("R_InitSprites: Sprite frame has multip rot=0 lump");
        }

        if (sprtemp[frame].rotate == 1) {
            std.debug.print("R_InitSprites: Sprite {s} frame {c} has rotations and a rot=0 lump\n", .{spritename, 'A' + @as(u8, @intCast(frame))});
            @panic("R_InitSprites: Sprite {s} frame {c} has rotations and a rot=0 lump");
        }

        sprtemp[frame].rotate = 0;
        for (0 .. 8) |rot| {
            sprtemp[frame].lump[rot] = @intCast(lump - r.data.firstspritelump);
            sprtemp[frame].flip[rot] = @intFromBool(flipped);
        }

        return;
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

    sprtemp[frame].lump[rotation] = @intCast(lump - r.data.firstspritelump);
    sprtemp[frame].flip[rotation] = @intFromBool(flipped);

}
