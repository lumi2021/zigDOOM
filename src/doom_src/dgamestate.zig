const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");
const enums = @import("enums/enums.zig");

pub const SCREEN_WIDTH = 320;
pub const SCREEN_HEIGHT = 200;

pub var modified_game: bool = false;
pub var gamemode: enums.Games = .indetermined;
pub var skill_level: enums.Skills = undefined;
pub var start_episode: u8 = undefined;
pub var start_map: u8 = undefined;

// settings (or defaults)
pub var mouseSensitivity: i32 = undefined;

pub var sound_sfxVolume: i32 = undefined;
pub var sound_musicVolume: i32 = undefined;

pub var showMessages: i32 = undefined;

pub var screenblocks: i32 = undefined;
