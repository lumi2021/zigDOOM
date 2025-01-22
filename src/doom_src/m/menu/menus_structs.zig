pub const DoomMenus = enum {
    newgame,
    options,
    loadgame,
    savegame,
    readthis,
    quitdoom,
    main_end
};

pub const MenuScreen = struct {
    numitens: i16,
    prevMenu: ?*MenuScreen,
    menuitens: [*]MenuItem,
    // draw routine
    x: i16,
    y: i16,
    lastOn: i16
};

pub const MenuItem = struct {
    status: i16,
    name: [10]u8,
    routine: *fn (i32) void,
    hotkey: u8
};
