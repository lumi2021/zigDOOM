const root = @import("root");


playerState: PlayerState,

health: usize,
armor: usize,

armortype: u8,


pub const PlayerState = enum {
    alive,
    dead,
    reborn,
};
