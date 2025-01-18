const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");
const enums = @import("enums/enums.zig");

pub var modified_game: bool = false;
pub var skill_level: enums.skills = undefined;
pub var start_episode: u8 = undefined;
pub var start_map: u8 = undefined;