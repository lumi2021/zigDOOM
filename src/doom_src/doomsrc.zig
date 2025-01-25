pub const main = @import("dmain.zig");
pub const resources = @import("dresources.zig");
pub const gamestate = @import("dgamestate.zig");
pub const zone = z.zone;

pub const am = @import("am/am.zig");
pub const d = @import("d/d.zig");
pub const f = @import("f/f.zig");
pub const g = @import("g/g.zig");
pub const hu = @import("hu/hu.zig");
pub const i = @import("i/i.zig");
pub const m = @import("m/m.zig");
pub const p = @import("p/p.zig");
pub const r = @import("r/r.zig");
pub const s = @import("s/s.zig");
pub const st = @import("st/st.zig");
pub const v = @import("v/v.zig");
pub const w = @import("w/w.zig");
pub const z = @import("z/z.zig");

pub const enums = @import("enums/enums.zig");

pub fn zig_init() !void {
    resources.init();
}