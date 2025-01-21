pub const main = @import("dmain.zig");
pub const resources = @import("dresources.zig");
pub const gamestate = @import("dgamestate.zig");

pub const wad = @import("wad.zig");

pub const enums = @import("enums/enums.zig");

pub const sys = @import("system/system.zig");

pub fn zig_init() !void {
    resources.init();
}