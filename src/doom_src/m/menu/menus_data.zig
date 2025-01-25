const MenuScreen = @import("menus_structs.zig").MenuScreen;
const MenuItem = @import("menus_structs.zig").MenuItem;
const DoomMenus = @import("menus_structs.zig").DoomMenus;

const menu = @import("../menu.zig");

pub var MainMenuOptions = [_]MenuItem{
    .{.status = 1, .name = "_NGAME", .routine = menu.choise_NewGame, .hotkey = 'n' },
    .{.status = 1, .name = "M_OPTION", .routine = menu.choise_Settings, .hotkey = 'o' },
    .{.status = 1, .name = "M_LOADG", .routine = menu.choise_LoadGame, .hotkey = 'l' },
    .{.status = 1, .name = "M_SAVEG", .routine = menu.choise_SaveGame, .hotkey = 's' },
    .{.status = 1, .name = "M_RDTHIS", .routine = menu.choise_ReadThis, .hotkey = 'r' },
    .{.status = 1, .name = "M_QUITG", .routine = menu.choise_QuitGame, .hotkey = 'q' },
};
pub var mainDef: MenuScreen = .{
    .prevMenu = null,
    .menuitens = &MainMenuOptions,
    .x = 97,
    .y = 64,
    .lastOn = 0
};

pub var EpisodeMenu = [_]MenuItem{
    .{.status = 1, .name = "M_EPI1", .routine = menu.choose_episode, .hotkey = 'k' },
    .{.status = 1, .name = "M_EPI2", .routine = menu.choose_episode, .hotkey = 't' },
    .{.status = 1, .name = "M_EPI3", .routine = menu.choose_episode, .hotkey = 'i' },
    .{.status = 1, .name = "M_EPI4", .routine = menu.choose_episode, .hotkey = 't' },
};
pub var epiDef: MenuScreen = .{
    .prevMenu = &mainDef,
    .menuitens = &EpisodeMenu,
    .x = 48,
    .y = 63,
    .lastOn = 0
};

pub var NewGameMenu = [_]MenuItem{
    .{.status = 1, .name = "M_JKILL", .routine = menu.choose_skill, .hotkey = 'i' },
    .{.status = 1, .name = "M_ROUGH", .routine = menu.choose_skill, .hotkey = 'h' },
    .{.status = 1, .name = "M_HURT",  .routine = menu.choose_skill, .hotkey = 'h' },
    .{.status = 1, .name = "M_ULTRA", .routine = menu.choose_skill, .hotkey = 'u' },
    .{.status = 1, .name = "M_NMARE", .routine = menu.choose_skill, .hotkey = 'n' },
};
pub var newDef: MenuScreen = .{
    .prevMenu = &epiDef,
    .menuitens = &NewGameMenu,
    .x = 48,
    .y = 63,
    .lastOn = 2
};
