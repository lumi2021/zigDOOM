const std = @import("std");
const root = @import("root");
const system = root.system;

var singletics = true;
pub var running = true;

pub fn gameloop() !noreturn {

    try system.init_graphics();

    while (running) {

        system.start_frame();


        if (singletics) {
            system.start_tic();

        } else {

        }

    }

    std.process.exit(0);    
}
