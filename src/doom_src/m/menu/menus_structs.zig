pub const MenuScreen = struct {
    prevMenu: ?*MenuScreen,
    menuitens: []MenuItem,
    // draw routine
    x: i16,
    y: i16,
    lastOn: i16
};

pub const MenuItem = struct {
    status: i16,
    name: *const [10]u8,
    routine: *const fn (i32) void,
    hotkey: u8
};
