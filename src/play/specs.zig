const std = @import("std");
const root = @import("root");

const wad = root.resources.wad;
const rendering = root.rendering;
const data = rendering.data;

pub const MAXSWITCHES = 50;
const MAXANIMS = 32;

// Animating textures and planes
// There is another anim_t used in wi_stuff, unrelated.
const Anim = struct {
    isTexture: bool,
    picnum: usize,
    basepic: usize,
    numpics: usize,
    speed: usize
};
//      source animation definition
const AnimDef = struct {
    isTexture: bool,
    endname: [:0]const u8,
    startname: [:0]const u8,
    speed: usize
};

const anim_defs = [_]AnimDef{
    .{ .isTexture = false, .endname = "NUKAGE3", .startname = "NUKAGE1",  .speed = 8},
    .{ .isTexture = false, .endname = "FWATER4", .startname = "FWATER1",  .speed = 8},
    .{ .isTexture = false, .endname = "SWATER4", .startname = "SWATER1",  .speed = 8},
    .{ .isTexture = false, .endname = "LAVA4",   .startname = "LAVA1",    .speed = 8},
    .{ .isTexture = false, .endname = "BLOOD3",  .startname = "BLOOD1",   .speed = 8},

    // DOOM II flat animations.
    .{ .isTexture = false, .endname = "RROCK08", .startname = "RROCK05",  .speed = 8},		
    .{ .isTexture = false, .endname = "SLIME04", .startname = "SLIME01",  .speed = 8},
    .{ .isTexture = false, .endname = "SLIME08", .startname = "SLIME05",  .speed = 8},
    .{ .isTexture = false, .endname = "SLIME12", .startname = "SLIME09",  .speed = 8},

    .{ .isTexture = true, .endname = "BLODGR4",  .startname = "BLODGR1",  .speed = 8},
    .{ .isTexture = true, .endname = "SLADRIP3", .startname = "SLADRIP1", .speed = 8},

    .{ .isTexture = true, .endname = "BLODRIP4", .startname = "BLODRIP1", .speed = 8},
    .{ .isTexture = true, .endname = "FIREWALL", .startname = "FIREWALA", .speed = 8},
    .{ .isTexture = true, .endname = "GSTFONT3", .startname = "GSTFONT1", .speed = 8},
    .{ .isTexture = true, .endname = "FIRELAVA", .startname = "FIRELAV3", .speed = 8},
    .{ .isTexture = true, .endname = "FIREMAG3", .startname = "FIREMAG1", .speed = 8},
    .{ .isTexture = true, .endname = "FIREBLU2", .startname = "FIREBLU1", .speed = 8},
    .{ .isTexture = true, .endname = "ROCKRED3", .startname = "ROCKRED1", .speed = 8},

    .{ .isTexture = true, .endname = "BFALL4",   .startname = "BFALL1",   .speed = 8},
    .{ .isTexture = true, .endname = "SFALL4",   .startname = "SFALL1",   .speed = 8},
    .{ .isTexture = true, .endname = "WFALL4",   .startname = "WFALL1",   .speed = 8},
    .{ .isTexture = true, .endname = "DBRAIN4",  .startname = "DBRAIN1",  .speed = 8},
};

var anims: [MAXANIMS]Anim = undefined;
var last_anim: [*]Anim = undefined;

pub const SwitchList = struct {
    name1: [:0]const u8,
    name2: [:0]const u8,
    episode: u16
};

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/p_spec.c#L148
pub fn init_pic_anims() !void {
    // Init animation
    last_anim = &anims;

    for (anim_defs) |animdefs_i| {
        if (animdefs_i.isTexture) {
            // different episode ?
            if (rendering.check_texture_num_for_name(animdefs_i.startname) == null) continue;

            last_anim[0].picnum = rendering.texture_num_for_name(animdefs_i.endname);
            last_anim[0].basepic = rendering.texture_num_for_name(animdefs_i.startname);
        } else {
            if (wad.check_num_for_name(animdefs_i.startname) == null) continue;

            last_anim[0].picnum = rendering.flat_num_for_name(animdefs_i.endname);
            last_anim[0].basepic = rendering.flat_num_for_name(animdefs_i.startname);
        }

        last_anim[0].isTexture = animdefs_i.isTexture;
        last_anim[0].numpics = last_anim[0].picnum - last_anim[0].basepic + 1;

        if (last_anim[0].numpics < 2) {
            std.debug.panic("P_InitPicAnims: bad cycle from {s} to {s}\n",
                .{animdefs_i.startname, animdefs_i.endname});
        }

        last_anim[0].speed = animdefs_i.speed;
        last_anim = last_anim[1..];
    }
}