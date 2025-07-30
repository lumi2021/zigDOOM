const root = @import("root");
const player = @import("play/player.zig");

pub var players: [4]player = undefined;
pub var paused: bool = undefined;
pub var usergame: bool = undefined;
pub var gameaction: GameAction = undefined;
pub var gamestate: GameState = undefined;


const GameAction = enum {
    nothing,
    load_level,
    new_game,
    load_game,
    save_game,
    play_demo,
    completed,
    victory,
    world_done,
    screenshot
};
const GameState = enum {
    level,
    intermission,
    finale,
    demoscreen,
};
