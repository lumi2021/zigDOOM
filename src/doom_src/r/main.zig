const root = @import("root");
const dsrc = root.doom_src;

const r = @import("r.zig");

pub fn init() void {

    r.data.init_data();

}
