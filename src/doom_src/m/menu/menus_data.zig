const MenuScreen = @import("menus_structs.zig").MenuScreen;
const MenuItem = @import("menus_structs.zig").MenuItem;
const DoomMenus = @import("menus_structs.zig").DoomMenus;

const menu = @import("../menu.zig");

const MainMenuOptions: []MenuItem = .{
    .{.status = 1, .name = "M_NGAME", .routine = menu.choise_NewGame, .hotkey = 'n' },
    .{.status = 1, .name = "M_OPTION", .routine = menu.choise_Settings, .hotkey = 'o' },
    .{.status = 1, .name = "M_LOADG", .routine = menu.choise_LoadGame, .hotkey = 'l' },
    .{.status = 1, .name = "M_SAVEG", .routine = menu.choise_SaveGame, .hotkey = 's' },
    .{.status = 1, .name = "M_RDTHIS", .routine = menu.choise_ReadThis, .hotkey = 'r' },
    .{.status = 1, .name = "M_QUITG", .routine = menu.choise_QuitGame, .hotkey = 'q' },
};

pub const mainDef: MenuScreen = .{
    .numitens = @intFromEnum(DoomMenus.main_end),
    .prevMenu = null,
    .menuitens = MainMenuOptions,
    .x = 97,
    .y = 64,
    .lastOn = 0
};


