const root = @import("root");
const dsrc = root.doom_src;

const r_data = @import("data.zig");

pub fn init() !void {

    try r_data.init_data();

}
