const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");


pub const SCREEN_WIDTH = 320;
pub const SCREEN_HEIGHT = 200;

pub var modified_game = false;
pub var gamemode: Games = .indetermined;

pub var skill_level: SkillLevel = undefined;
pub var start_episode: usize = 0;
pub var start_map: usize = 0;


// settings (called defaults)
pub var mouseSensitivity: i32 = undefined;

pub var sound_sfxVolume: i32 = undefined;
pub var sound_musicVolume: i32 = undefined;

pub var showMessages: i32 = undefined;

pub var screenblocks: i32 = undefined;


// enums
pub const Games = enum {
    shareware,
    
    registered,
    retail,
    commecial,

    indetermined
};
pub const SkillLevel = enum {
    baby,
    easy,
    medium,
    hard,
    nightmare
};
