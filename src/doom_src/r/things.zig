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
        const spritename = namelist[i];
        // memset here

        maxframe = -1;
        const intname = std.mem.readInt(u32, spritename[0..4], .little);

        // scan the lumps,
	    //  filling in the frames for whatever is found
        for ((start+1) .. end) |l| {
            if (w.wad.lumpinfo[l].name32[0] == intname) {
                const frame = w.wad.lumpinfo[l].name[4] - 'A';
                const rotation = w.wad.lumpinfo[l].name[5] - '0';

                var patched: i32 = undefined;
                if (doomsrc.gamestate.modified_game) patched = w.wad.get_num_for_name(w.wad.lumpinfo[i].name)
                else patched = l;

                install_sprite_lump(patched, frame, rotation, true);
            }
        }
    }

}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/r_things.c#L106
fn install_sprite_lump(lump: i32, frame: u32, rotation: u32, flipped: bool) void {

}
