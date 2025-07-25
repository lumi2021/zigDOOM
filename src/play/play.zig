const switches = @import("switches.zig");
const spec = @import("specs.zig");
const things = @import("root").rendering.things;
const info = @import("root").info;

pub fn init() !void {
    try switches.init_switch_list();
    try spec.init_pic_anims();
    try things.init_sprites(@constCast(&info.sprnames));
}
