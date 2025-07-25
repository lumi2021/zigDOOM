const menu = @import("menu.zig");
const MenuItem = menu.MenuItem;
const MenuScreen = menu.MenuScreen;

pub var MainMenuOptions = [_]MenuItem{
    .{.status = 1, .name = "_NGAME" ++ "\x00" ** 4, .routine = menu.choise_NewGame, .hotkey = 'n' },
    .{.status = 1, .name = "M_OPTION" ++ "\x00" ** 2, .routine = menu.choise_Settings, .hotkey = 'o' },
    .{.status = 1, .name = "M_LOADG" ++ "\x00" ** 3, .routine = menu.choise_LoadGame, .hotkey = 'l' },
    .{.status = 1, .name = "M_SAVEG" ++ "\x00" ** 3, .routine = menu.choise_SaveGame, .hotkey = 's' },
    .{.status = 1, .name = "M_RDTHIS" ++ "\x00" ** 2, .routine = menu.choise_ReadThis, .hotkey = 'r' },
    .{.status = 1, .name = "M_QUITG" ++ "\x00" ** 3, .routine = menu.choise_QuitGame, .hotkey = 'q' },
};
pub var mainDef: MenuScreen = .{
    .prevMenu = null,
    .menuitens = &MainMenuOptions,
    .x = 97,
    .y = 64,
    .lastOn = 0
};

pub var EpisodeMenu = [_]MenuItem{
    .{.status = 1, .name = "M_EPI1" ++ "\x00" ** 4, .routine = menu.choose_episode, .hotkey = 'k' },
    .{.status = 1, .name = "M_EPI2" ++ "\x00" ** 4, .routine = menu.choose_episode, .hotkey = 't' },
    .{.status = 1, .name = "M_EPI3"  ++ "\x00" ** 4, .routine = menu.choose_episode, .hotkey = 'i' },
    .{.status = 1, .name = "M_EPI4"  ++ "\x00" ** 4, .routine = menu.choose_episode, .hotkey = 't' },
};
pub var epiDef: MenuScreen = .{
    .prevMenu = &mainDef,
    .menuitens = &EpisodeMenu,
    .x = 48,
    .y = 63,
    .lastOn = 0
};

pub var NewGameMenu = [_]MenuItem{
    .{.status = 1, .name = "M_JKILL" ++ "\x00" ** 3, .routine = menu.choose_skill, .hotkey = 'i' },
    .{.status = 1, .name = "M_ROUGH" ++ "\x00" ** 3, .routine = menu.choose_skill, .hotkey = 'h' },
    .{.status = 1, .name = "M_HURT"  ++ "\x00" ** 4, .routine = menu.choose_skill, .hotkey = 'h' },
    .{.status = 1, .name = "M_ULTRA" ++ "\x00" ** 3, .routine = menu.choose_skill, .hotkey = 'u' },
    .{.status = 1, .name = "M_NMARE" ++ "\x00" ** 3, .routine = menu.choose_skill, .hotkey = 'n' },
};
pub var newDef: MenuScreen = .{
    .prevMenu = &epiDef,
    .menuitens = &NewGameMenu,
    .x = 48,
    .y = 63,
    .lastOn = 2
};