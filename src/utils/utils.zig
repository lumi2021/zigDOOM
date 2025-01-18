pub const args_handler = @import("args_handler.zig");

// initialize all util libraries that need some initializing
pub fn init() !void {
    try args_handler.init();
}
