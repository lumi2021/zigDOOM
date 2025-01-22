// Implementation of:
// https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/m_menu.c
const MenuScreen = @import("menu/menus_structs.zig").MenuScreen;
const menu_data = @import("menu/menus_data.zig");

var currentMenu: *MenuScreen = null;

// options
pub fn choise_NewGame(_: i32) void {}
pub fn choise_Settings(_: i32) void {}
pub fn choise_LoadGame(_: i32) void {}
pub fn choise_SaveGame(_: i32) void {}
pub fn choise_ReadThis(_: i32) void {}
pub fn choise_QuitGame(_: i32) void {}

pub fn init() void {

    currentMenu = &menu_data.mainDef;
    @compileError("FIXME implement it :p");

}